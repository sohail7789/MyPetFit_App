# Account deletion

What happens today, where the gap is, and exactly what would close it.

Nothing in this document has been deployed. It is a specification for work
that requires Firebase configuration and a billing change, and those are the
project owner's decisions to make — not something to create silently in a
repository and leave for someone to discover.

---

## What ships today

`lib/services/account_deletion.dart` composes two existing services and runs
entirely on the user's device, with the user's own credentials:

1. **Read the pet ids** from Firestore, while the documents still exist.
2. **Delete Storage objects** — the owner photo and each pet photo, at their
   deterministic paths (`users/{uid}/profile/profile.jpg`,
   `users/{uid}/pets/{petId}/profile.jpg`).
3. **Delete Firestore documents** under `users/{uid}`.
4. **Delete the Firebase Authentication account**, re-authenticating first
   when Firebase judges the session too old.

The ordering is deliberate and correct. Storage objects are addressed by pet
ids held in Firestore, so they must go while those documents are readable;
the auth account must outlive its data, because the security rules scope
every document to the uid — delete the account first and the data becomes
unreachable by any session, which is abandonment, not erasure.

`lib/screens/account/delete_account_screen.dart` clears local state only
*after* the remote deletion has succeeded, so a failure leaves the user with
their account and their data intact and says so. Pending OS reminders are
cancelled at the same point, since they name the pet they are about.

This is covered by `test/account_deletion_test.dart` and
`test/account_erasure_test.dart`.

## The gap

**Client-side erasure is best-effort, and cannot be made otherwise.**

The sequence above is four network round trips on a mobile device. Between
any two of them the process can be killed, the network can drop, or the user
can force-quit the app. Nothing afterwards reconciles what was missed:

| Interrupted after | Left behind |
|---|---|
| step 1 | nothing — no writes yet |
| step 2 | Firestore documents, and the auth account |
| step 3 | the auth account, with no data |
| step 4 | nothing |

The worst case is an interruption between steps 2 and 3: Storage objects are
gone, documents remain, and the user has been shown no confirmation. They can
retry — every delete is idempotent and tolerant of an object that was never
created — but if they simply never open the app again, the documents stay
indefinitely.

A retry is also impossible in one specific case: if the *auth account* is
deleted but data deletion failed earlier, the user can no longer sign in, and
their remaining documents are unreachable by any client. The current ordering
avoids this by deleting data first, which is why the ordering must not be
changed casually.

## What would close it

A Cloud Function on the Authentication delete trigger. This is the only
mechanism that runs on Google's infrastructure rather than the user's device,
so it completes regardless of what the handset does after the request.

### Exactly what is needed

**1. Blaze (pay-as-you-go) billing on `mypetfit-c530e`.** Cloud Functions
cannot be deployed on the free Spark plan. For this workload — one invocation
per account deletion — the cost is effectively zero, but the plan change is a
billing decision and requires a card on file.

**2. A `functions/` directory** with a single function:

- **Trigger:** `functions.auth.user().onDelete()` (1st gen) or the
  Identity Platform blocking/lifecycle equivalent (2nd gen).
- **Runtime:** Node.js, using `firebase-admin`, which bypasses security
  rules and therefore needs no rule changes.
- **What it must delete, for the deleted `uid`:**
  - The Firestore document `users/{uid}` **and every subcollection beneath
    it**. A Firestore document delete does *not* cascade to subcollections,
    so this must enumerate them — `pets`, and `assessments` beneath each pet.
    The Admin SDK's `firestore.recursiveDelete(docRef)` does this in one
    call and is the intended tool.
  - The Storage prefix `users/{uid}/`, via
    `bucket.deleteFiles({ prefix: 'users/' + uid + '/' })`. Deleting by
    prefix — rather than by the deterministic paths the client uses — also
    collects anything the client never knew about.
- **Idempotency:** it must tolerate everything already being gone, because
  the client will usually have deleted most of it first.

**3. Deployment:** `firebase deploy --only functions`, plus adding the
function's region to whatever CI runs deployments.

**4. A rules-test addition** (`rules_test/rules.test.js`) is *not* required:
the Admin SDK bypasses rules, so there is no rule surface to test. The
function needs its own unit test against the Firestore emulator instead.

### What the client keeps doing afterwards

The client-side deletion should **stay** once the function exists. It is what
makes deletion feel immediate — the user sees their data gone before they
leave the screen — and it keeps working if the function is ever unhealthy.
The function becomes the backstop that guarantees completion, not a
replacement for the foreground path.

## Store requirements

Both stores require in-app account deletion, and this app has it. Apple
Guideline 5.1.1(v) additionally requires that accounts created with Sign in
with Apple can be deleted; `_reauthenticate` handles the Apple branch
explicitly for that reason.

Neither store requires the deletion to be server-guaranteed. The gap
described here is a data-hygiene and GDPR-erasure concern, not a submission
blocker.
