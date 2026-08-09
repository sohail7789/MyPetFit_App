/**
 * MyPetFit — security-rules test suite.
 *
 * Proves two things before anything is deployed:
 *   1. The proposed rules CLOSE the currently-open production hole.
 *   2. The proposed rules do not BREAK any legitimate operation the Flutter
 *      app actually performs.
 *
 * Every case below is traced to a real call site in lib/. Where a test has a
 * `// lib/...` reference, that is the line the test exists to protect.
 *
 * Runs only against the emulator on project id `demo-mypetfit`. The `demo-`
 * prefix makes the emulator refuse to contact any live Firebase backend, so
 * this suite cannot touch production even if misconfigured.
 *
 *   cd rules_test && npm install && npm test
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, deleteDoc, collection, getDocs,
  query, where, orderBy, limit, writeBatch, serverTimestamp,
} = require('firebase/firestore');
const {
  ref, uploadBytes, getBytes, deleteObject,
} = require('firebase/storage');

const ROOT = path.resolve(__dirname, '..');
const A = 'userA';
const B = 'userB';

let env;

// Small helpers so the intent of each test reads at a glance.
const anon = () => env.unauthenticatedContext();
const user = (uid) => env.authenticatedContext(uid);
const admin = () => env.authenticatedContext('adminUser', { admin: true });

const bytes = (n) => new Uint8Array(n);
const IMG = { contentType: 'image/webp' };
const PDF = { contentType: 'application/pdf' };

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-mypetfit',
    firestore: {
      rules: fs.readFileSync(path.join(ROOT, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: fs.readFileSync(path.join(ROOT, 'storage.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

after(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();

  // Seed with rules disabled — this is fixture setup, not a test.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'products/p1'), {
      name: 'Gut Probiotic Powder', active: true, price: 649, imageUrl: '',
    });
    await setDoc(doc(db, 'products/p2'), { name: 'Inactive', active: false });

    for (const uid of [A, B]) {
      await setDoc(doc(db, `users/${uid}`), { ownerName: `Owner ${uid}`, email: `${uid}@example.com` });
      await setDoc(doc(db, `users/${uid}/pets/pet1`), { id: 'pet1', name: 'Bruno' });
      await setDoc(doc(db, `users/${uid}/pets/pet1/assessments/1000`), {
        petId: 'pet1', percentageScore: 72, completedAt: '2026-08-01T00:00:00.000Z',
      });
    }
    await setDoc(doc(db, 'admins/adminUser'), { email: 'admin@mypetfit.in' });

    const st = ctx.storage();
    await uploadBytes(ref(st, 'products/p1/primary.webp'), bytes(128), IMG);
    await uploadBytes(ref(st, 'products/p1/gallery/g1.webp'), bytes(128), IMG);
    await uploadBytes(ref(st, `users/${A}/pets/pet1/photo.webp`), bytes(128), IMG);
    await uploadBytes(ref(st, `users/${B}/pets/pet1/photo.webp`), bytes(128), IMG);
  });
});

// =====================================================================
// FIRESTORE — product catalogue
// =====================================================================
describe('Firestore / products', () => {
  // lib/main.dart:110 fires this with no session. THE critical case.
  it('anonymous reads a product document', async () => {
    await assertSucceeds(getDoc(doc(anon().firestore(), 'products/p1')));
  });

  // lib/services/firestore_service.dart:43 — the exact production query.
  it('anonymous runs the real catalogue query where(active == true)', async () => {
    const snap = await assertSucceeds(getDocs(
      query(collection(anon().firestore(), 'products'), where('active', '==', true)),
    ));
    assert.strictEqual(snap.size, 1, 'expected only the active product');
  });

  it('anonymous lists products with no filter at all', async () => {
    // The rule is `if true` — a constant — so it cannot depend on the query
    // shape. Asserting this pins that the public read is genuinely public
    // and not accidentally coupled to the `active` filter.
    await assertSucceeds(getDocs(collection(anon().firestore(), 'products')));
  });

  it('authenticated user reads a product', async () => {
    await assertSucceeds(getDoc(doc(user(A).firestore(), 'products/p1')));
  });

  it('anonymous CANNOT create a product', async () => {
    await assertFails(setDoc(doc(anon().firestore(), 'products/evil'), { name: 'x' }));
  });

  it('anonymous CANNOT update a product', async () => {
    await assertFails(setDoc(doc(anon().firestore(), 'products/p1'), { price: 1 }, { merge: true }));
  });

  it('authenticated non-admin CANNOT create a product', async () => {
    await assertFails(setDoc(doc(user(A).firestore(), 'products/evil'), { name: 'x' }));
  });

  it('authenticated non-admin CANNOT update a product price', async () => {
    await assertFails(setDoc(doc(user(A).firestore(), 'products/p1'), { price: 1 }, { merge: true }));
  });

  it('authenticated non-admin CANNOT delete a product', async () => {
    await assertFails(deleteDoc(doc(user(A).firestore(), 'products/p1')));
  });

  it('admin CAN create a product', async () => {
    await assertSucceeds(setDoc(doc(admin().firestore(), 'products/p3'), { name: 'New', active: true }));
  });

  it('admin CAN update a product', async () => {
    await assertSucceeds(setDoc(doc(admin().firestore(), 'products/p1'), { price: 599 }, { merge: true }));
  });

  it('admin CAN delete a product', async () => {
    await assertSucceeds(deleteDoc(doc(admin().firestore(), 'products/p1')));
  });
});

// =====================================================================
// FIRESTORE — user isolation
// =====================================================================
describe('Firestore / users', () => {
  it('user A reads own profile', async () => {            // firestore_service.dart:74
    await assertSucceeds(getDoc(doc(user(A).firestore(), `users/${A}`)));
  });

  it('user A CANNOT read user B profile', async () => {
    await assertFails(getDoc(doc(user(A).firestore(), `users/${B}`)));
  });

  it('user A merge-writes own profile', async () => {     // firestore_service.dart:61
    await assertSucceeds(setDoc(doc(user(A).firestore(), `users/${A}`),
      { ownerName: 'Renamed' }, { merge: true }));
  });

  it('user A merge-writes own consent', async () => {     // firestore_service.dart:101
    await assertSucceeds(setDoc(doc(user(A).firestore(), `users/${A}`),
      { consent: { accepted: true } }, { merge: true }));
  });

  it('user A CANNOT write user B profile', async () => {
    await assertFails(setDoc(doc(user(A).firestore(), `users/${B}`),
      { ownerName: 'Hacked' }, { merge: true }));
  });

  it('user A CANNOT delete user B profile', async () => {
    await assertFails(deleteDoc(doc(user(A).firestore(), `users/${B}`)));
  });

  it('anonymous CANNOT enumerate the users collection', async () => {
    await assertFails(getDocs(collection(anon().firestore(), 'users')));
  });

  it('authenticated user CANNOT enumerate the users collection', async () => {
    await assertFails(getDocs(collection(user(A).firestore(), 'users')));
  });

  // ---- REGRESSION GUARD -------------------------------------------
  // lib/services/auth_service.dart:386 isEmailRegistered() runs exactly this
  // query, from the Forgot Password screen, while SIGNED OUT.
  //
  // It MUST fail — allowing it would be an anonymous account-enumeration
  // oracle over every registered email. This test asserts the hole stays
  // shut. The app-side fix is to delete isEmailRegistered() and let
  // sendPasswordResetEmail() report an unknown address, which it already
  // does (auth_service.dart:187).
  it('anonymous CANNOT query users by email (isEmailRegistered must stay denied)', async () => {
    await assertFails(getDocs(query(
      collection(anon().firestore(), 'users'),
      where('email', '==', 'userA@example.com'),
      limit(1),
    )));
  });
});

// =====================================================================
// FIRESTORE — pets and assessments
// =====================================================================
describe('Firestore / pets and assessments', () => {
  it('user A reads own pet', async () => {
    await assertSucceeds(getDoc(doc(user(A).firestore(), `users/${A}/pets/pet1`)));
  });

  it('user A LISTS own pets', async () => {               // firestore_service.dart:148
    await assertSucceeds(getDocs(collection(user(A).firestore(), `users/${A}/pets`)));
  });

  it('user A CANNOT read user B pet', async () => {
    await assertFails(getDoc(doc(user(A).firestore(), `users/${B}/pets/pet1`)));
  });

  it('user A CANNOT list user B pets', async () => {
    await assertFails(getDocs(collection(user(A).firestore(), `users/${B}/pets`)));
  });

  it('user A merge-writes own pet', async () => {         // firestore_service.dart:133
    await assertSucceeds(setDoc(doc(user(A).firestore(), `users/${A}/pets/pet1`),
      { name: 'Bruno II' }, { merge: true }));
  });

  it('user A reads own assessment', async () => {
    await assertSucceeds(getDoc(doc(user(A).firestore(), `users/${A}/pets/pet1/assessments/1000`)));
  });

  it('user A LISTS own assessments ordered by completedAt', async () => { // firestore_service.dart:207
    await assertSucceeds(getDocs(query(
      collection(user(A).firestore(), `users/${A}/pets/pet1/assessments`),
      orderBy('completedAt', 'desc'),
    )));
  });

  it('user A CANNOT read user B assessment', async () => {
    await assertFails(getDoc(doc(user(A).firestore(), `users/${B}/pets/pet1/assessments/1000`)));
  });

  it('user A CANNOT list user B assessments', async () => {
    await assertFails(getDocs(collection(user(A).firestore(), `users/${B}/pets/pet1/assessments`)));
  });

  // ---- The saveAssessment batch, exactly as the app issues it ------
  // firestore_service.dart:172-203. A batch is atomic under rules too: if
  // EITHER op is denied the whole commit fails. This is the single most
  // load-bearing write in the app.
  it('user A commits the real assessment batch (assessment doc + parent pet merge)', async () => {
    const db = user(A).firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${A}/pets/pet1/assessments/2000`), {
      petId: 'pet1', percentageScore: 81, completedAt: '2026-08-09T00:00:00.000Z',
    });
    batch.set(doc(db, `users/${A}/pets/pet1`), {
      lastAssessmentAt: '2026-08-09T00:00:00.000Z',
      latestScore: 81,
      latestCategory: 'good',
    }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  it('user A CANNOT commit that batch against user B', async () => {
    const db = user(A).firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${B}/pets/pet1/assessments/2000`), { percentageScore: 0 });
    batch.set(doc(db, `users/${B}/pets/pet1`), { latestScore: 0 }, { merge: true });
    await assertFails(batch.commit());
  });

  // A batch mixing own + foreign must fail WHOLESALE — proving the foreign
  // op cannot ride along on the legitimate one.
  it('a batch mixing own and foreign writes is rejected entirely', async () => {
    const db = user(A).firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, `users/${A}/pets/pet1`), { name: 'ok' }, { merge: true });
    batch.set(doc(db, `users/${B}/pets/pet1`), { name: 'not ok' }, { merge: true });
    await assertFails(batch.commit());
  });
});

// =====================================================================
// FIRESTORE — account deletion (firestore_service.dart:261-315)
// =====================================================================
describe('Firestore / account deletion', () => {
  it('user A deletes own assessment, own pet, then own user doc — in app order', async () => {
    const db = user(A).firestore();
    // deletePet(): list assessments, batch-delete them, delete the pet doc.
    const assessments = await assertSucceeds(
      getDocs(collection(db, `users/${A}/pets/pet1/assessments`)));
    const batch = writeBatch(db);
    assessments.forEach((d) => batch.delete(d.ref));
    await assertSucceeds(batch.commit());
    await assertSucceeds(deleteDoc(doc(db, `users/${A}/pets/pet1`)));
    // deleteAllUserData(): then the parent user document.
    await assertSucceeds(deleteDoc(doc(db, `users/${A}`)));
  });

  it('user A CANNOT delete user B pet', async () => {
    await assertFails(deleteDoc(doc(user(A).firestore(), `users/${B}/pets/pet1`)));
  });

  it('user A CANNOT delete user B assessment', async () => {
    await assertFails(deleteDoc(doc(user(A).firestore(), `users/${B}/pets/pet1/assessments/1000`)));
  });

  it('anonymous CANNOT delete a user document', async () => {
    await assertFails(deleteDoc(doc(anon().firestore(), `users/${A}`)));
  });
});

// =====================================================================
// FIRESTORE — admin boundary
// =====================================================================
describe('Firestore / admin boundary', () => {
  it('normal user CANNOT write admins/{uid} (no self-elevation)', async () => {
    await assertFails(setDoc(doc(user(A).firestore(), `admins/${A}`), { email: 'x' }));
  });

  it('admin CANNOT write the admins roster either (Admin SDK only)', async () => {
    await assertFails(setDoc(doc(admin().firestore(), 'admins/adminUser'), { email: 'y' }));
  });

  it('anonymous CANNOT read the admins roster', async () => {
    await assertFails(getDoc(doc(anon().firestore(), 'admins/adminUser')));
  });

  it('normal user CANNOT read the admins roster', async () => {
    await assertFails(getDoc(doc(user(A).firestore(), 'admins/adminUser')));
  });

  it('admin CAN read the admins roster', async () => {
    await assertSucceeds(getDoc(doc(admin().firestore(), 'admins/adminUser')));
  });

  // The boundary that matters most: catalogue rights are not health-data
  // rights.
  it('admin CANNOT read another user profile', async () => {
    await assertFails(getDoc(doc(admin().firestore(), `users/${A}`)));
  });

  it('admin CANNOT read another user pet', async () => {
    await assertFails(getDoc(doc(admin().firestore(), `users/${A}/pets/pet1`)));
  });

  it('admin CANNOT read another user assessment', async () => {
    await assertFails(getDoc(doc(admin().firestore(), `users/${A}/pets/pet1/assessments/1000`)));
  });

  // Proves the design choice: rules read the TOKEN, never a document field.
  // A user may freely write `admin: true` into their own profile; it is inert.
  it('writing admin:true into your own user doc grants nothing', async () => {
    const db = user(A).firestore();
    await assertSucceeds(setDoc(doc(db, `users/${A}`), { admin: true, isAdmin: true }, { merge: true }));
    await assertFails(setDoc(doc(db, 'products/p1'), { price: 1 }, { merge: true }));
  });
});

// =====================================================================
// STORAGE — public product assets
// =====================================================================
describe('Storage / products', () => {
  it('anonymous reads the product primary image', async () => {
    await assertSucceeds(getBytes(ref(anon().storage(), 'products/p1/primary.webp')));
  });

  it('anonymous reads a gallery image', async () => {
    await assertSucceeds(getBytes(ref(anon().storage(), 'products/p1/gallery/g1.webp')));
  });

  it('authenticated non-admin reads the product image', async () => {
    await assertSucceeds(getBytes(ref(user(A).storage(), 'products/p1/primary.webp')));
  });

  it('non-admin CANNOT upload a product image', async () => {
    await assertFails(uploadBytes(ref(user(A).storage(), 'products/p1/primary.webp'), bytes(128), IMG));
  });

  it('anonymous CANNOT upload a product image', async () => {
    await assertFails(uploadBytes(ref(anon().storage(), 'products/p1/primary.webp'), bytes(128), IMG));
  });

  it('admin CAN upload a valid webp product image', async () => {
    await assertSucceeds(uploadBytes(ref(admin().storage(), 'products/p1/primary.webp'), bytes(128), IMG));
  });

  it('admin CAN upload into the gallery', async () => {
    await assertSucceeds(uploadBytes(ref(admin().storage(), 'products/p1/gallery/g2.webp'), bytes(128), IMG));
  });

  it('non-admin CANNOT delete a product image', async () => {
    await assertFails(deleteObject(ref(user(A).storage(), 'products/p1/primary.webp')));
  });

  // ---- THE METHOD-SPLIT REGRESSION GUARD --------------------------
  // If `create, update` and `delete` are ever collapsed back into a single
  // `allow write` that calls isImage()/underMB(), this test fails: on a
  // delete `request.resource` is null, the condition errors, and the delete
  // is denied. This is the trap this suite exists to keep shut.
  it('admin CAN delete a product image (request.resource is null on delete)', async () => {
    await assertSucceeds(deleteObject(ref(admin().storage(), 'products/p1/primary.webp')));
  });

  it('admin CAN delete a gallery image', async () => {
    await assertSucceeds(deleteObject(ref(admin().storage(), 'products/p1/gallery/g1.webp')));
  });

  it('oversized product image (6 MB) is rejected even for admin', async () => {
    await assertFails(uploadBytes(
      ref(admin().storage(), 'products/p1/primary.webp'), bytes(6 * 1024 * 1024), IMG));
  });

  it('wrong content type (PDF into a product path) is rejected even for admin', async () => {
    await assertFails(uploadBytes(
      ref(admin().storage(), 'products/p1/primary.webp'), bytes(128), PDF));
  });

  it('HEIC is rejected — the transcode-before-upload rule', async () => {
    await assertFails(uploadBytes(
      ref(admin().storage(), 'products/p1/primary.webp'), bytes(128), { contentType: 'image/heic' }));
  });
});

// =====================================================================
// STORAGE — private owner files
// =====================================================================
describe('Storage / private files', () => {
  it('user A reads own pet image', async () => {
    await assertSucceeds(getBytes(ref(user(A).storage(), `users/${A}/pets/pet1/photo.webp`)));
  });

  it('user A CANNOT read user B pet image', async () => {
    await assertFails(getBytes(ref(user(A).storage(), `users/${B}/pets/pet1/photo.webp`)));
  });

  it('anonymous CANNOT read a private pet image', async () => {
    await assertFails(getBytes(ref(anon().storage(), `users/${A}/pets/pet1/photo.webp`)));
  });

  it('admin CANNOT read a private pet image', async () => {
    await assertFails(getBytes(ref(admin().storage(), `users/${A}/pets/pet1/photo.webp`)));
  });

  it('user A CANNOT upload into user B space', async () => {
    await assertFails(uploadBytes(
      ref(user(A).storage(), `users/${B}/pets/pet1/photo.webp`), bytes(128), IMG));
  });

  it('user A uploads own avatar', async () => {
    await assertSucceeds(uploadBytes(
      ref(user(A).storage(), `users/${A}/profile/avatar.webp`), bytes(128), IMG));
  });

  it('user A deletes own pet image', async () => {
    await assertSucceeds(deleteObject(ref(user(A).storage(), `users/${A}/pets/pet1/photo.webp`)));
  });

  it('user A CANNOT delete user B pet image', async () => {
    await assertFails(deleteObject(ref(user(A).storage(), `users/${B}/pets/pet1/photo.webp`)));
  });

  it('user A uploads a PDF to own reports', async () => {
    await assertSucceeds(uploadBytes(
      ref(user(A).storage(), `users/${A}/reports/r1.pdf`), bytes(128), PDF));
  });

  it('user A CANNOT upload an image to own reports', async () => {
    await assertFails(uploadBytes(
      ref(user(A).storage(), `users/${A}/reports/r1.pdf`), bytes(128), IMG));
  });

  it('oversized PDF (11 MB) to reports is rejected', async () => {
    await assertFails(uploadBytes(
      ref(user(A).storage(), `users/${A}/reports/r1.pdf`), bytes(11 * 1024 * 1024), PDF));
  });

  it('an unmapped top-level path is denied by default', async () => {
    await assertFails(uploadBytes(ref(user(A).storage(), 'random/thing.webp'), bytes(128), IMG));
  });
});
