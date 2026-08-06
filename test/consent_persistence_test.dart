import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/models/consent_state.dart';
import 'package:mypetfit_app/models/owner_profile.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_cloud.dart';

/// The startup restore, end to end, against a fake account in the cloud.
///
/// The bug these cover: consent lived only in SharedPreferences and was never
/// written to Firestore, so anything that cleared that key — signing out, a
/// reinstall, a second device — dropped it. The router checks consent first,
/// so every returning user was sent back to /consent with their owner and
/// pets restored around them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PetInfo pet(String id, {String name = 'Bruno'}) => PetInfo(
        id: id,
        name: name,
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  OwnerProfile owner() => OwnerProfile(
        ownerName: 'Sohail',
        ownerPhone: '9000000000',
        ownerEmail: 'sohail@example.com',
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  ConsentState signed({DateTime? at}) => ConsentState(
        given: true,
        record: ConsentRecord(
          signatureName: 'Sohail',
          signedAt: at ?? DateTime.utc(2026, 1, 3),
        ),
        updatedAt: at ?? DateTime.utc(2026, 1, 3),
      );

  /// Runs the real startup sequence and reports where the router would land.
  Future<String> landingAfterStartup(
    PetInfoProvider pets, {
    AppStartupProvider? startup,
    FakeCloud? cloud,
  }) async {
    await (startup ?? AppStartupProvider()).initialize(
      petInfo: pets,
      quiz: QuizProvider(service: cloud ?? FakeCloud()),
    );
    return AppRoutes.landingFor(
      consentGiven: pets.consentGiven,
      hasOwner: pets.ownerInfo != null,
      hasPet: pets.pets.isNotEmpty,
    );
  }

  group('first-time user', () {
    test('an empty account lands on consent', () async {
      final pets = PetInfoProvider(service: FakeCloud());

      expect(await landingAfterStartup(pets), AppRoutes.consent);
      expect(pets.consentGiven, isFalse);
    });

    test('signing consent pushes it to the cloud', () async {
      final cloud = FakeCloud();
      final pets = PetInfoProvider(service: cloud);
      await pets.init();

      pets.giveConsent(signatureName: 'Sohail');
      // queueSync sends on the next microtask rather than inline.
      await Future<void>.delayed(Duration.zero);

      expect(cloud.consentWrites, 1);
      expect(cloud.consent?.given, isTrue);
      expect(cloud.consent?.record?.signatureName, 'Sohail');
    });
  });

  group('returning user after logout', () {
    test('consent comes back from the cloud, and they land home', () async {
      // Sign-out wipes the prefs key, so this device starts with nothing —
      // exactly the state the bug produced.
      final cloud = FakeCloud(
        consent: signed(),
        owner: owner(),
        pets: [pet('p1')],
      );

      final pets = PetInfoProvider(service: cloud);

      expect(await landingAfterStartup(pets), AppRoutes.home);
      expect(pets.consentGiven, isTrue);
      expect(pets.consentRecord?.signatureName, 'Sohail');
      // Adopted, not re-uploaded.
      expect(cloud.consentWrites, 0);
    });
  });

  group('already signed-in user after restart', () {
    test('a device that still has its cache also lands home', () async {
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,'
            '"consentUpdatedAt":"2026-01-03T00:00:00.000Z",'
            '"consentRecord":{"signatureName":"Sohail",'
            '"signedAt":"2026-01-03T00:00:00.000Z"}}',
      });

      final cloud = FakeCloud(
        consent: signed(),
        owner: owner(),
        pets: [pet('p1')],
      );

      expect(
        await landingAfterStartup(PetInfoProvider(service: cloud)),
        AppRoutes.home,
      );
    });

    test('a stale cache does not clobber a newer cloud decision', () async {
      // Consent withdrawn on another device after this one last synced.
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,'
            '"consentUpdatedAt":"2026-01-03T00:00:00.000Z"}',
      });

      final cloud = FakeCloud(
        consent: ConsentState(given: false, updatedAt: DateTime.utc(2026, 2)),
        owner: owner(),
        pets: [pet('p1')],
      );

      final pets = PetInfoProvider(service: cloud);
      expect(await landingAfterStartup(pets), AppRoutes.consent);
      expect(pets.consentGiven, isFalse);
    });
  });

  group('fresh install on a second device', () {
    test('adopts consent, owner and pets without asking again', () async {
      final cloud = FakeCloud(
        consent: signed(),
        owner: owner(),
        pets: [pet('p1', name: 'Bruno'), pet('p2', name: 'Mia')],
      );

      final pets = PetInfoProvider(service: cloud);

      expect(await landingAfterStartup(pets), AppRoutes.home);
      expect(pets.consentGiven, isTrue);
      expect(pets.pets.map((p) => p.name), ['Bruno', 'Mia']);
    });

    test('the adopted consent is cached for the next launch', () async {
      final cloud = FakeCloud(consent: signed(), owner: owner(), pets: [
        pet('p1'),
      ]);

      await landingAfterStartup(PetInfoProvider(service: cloud));

      // A second provider over the same prefs, cloud unreachable this time.
      final relaunched =
          PetInfoProvider(service: FakeCloud(offline: Exception('offline')));
      await relaunched.init();

      expect(relaunched.consentGiven, isTrue);
      expect(relaunched.consentUpdatedAt, DateTime.utc(2026, 1, 3));
    });
  });

  group('offline startup', () {
    test('a cached consent is not lost when the cloud is unreachable',
        () async {
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,'
            '"consentUpdatedAt":"2026-01-03T00:00:00.000Z"}',
      });

      final pets =
          PetInfoProvider(service: FakeCloud(offline: Exception('offline')));
      final startup = AppStartupProvider();

      await startup.initialize(
        petInfo: pets,
        quiz: QuizProvider(service: FakeCloud(offline: Exception('offline'))),
      );

      // The startup screen offers a retry rather than a dead spinner...
      expect(startup.hasFailed, isTrue);
      // ...and the failed reconcile left the local decision alone, so the
      // retry does not begin from a wiped consent flag.
      expect(pets.consentGiven, isTrue);
    });

    test('consent given offline reaches the cloud on the next sync', () async {
      final cloud = FakeCloud(offline: Exception('offline'));
      final pets = PetInfoProvider(service: cloud);
      await pets.init();

      pets.giveConsent(signatureName: 'Sohail');
      await Future<void>.delayed(Duration.zero);

      // Locally applied immediately; the write is still owed.
      expect(pets.consentGiven, isTrue);
      expect(cloud.consentWrites, 0);
      expect(pets.hasPendingSync, isTrue);
    });
  });

  group('consent migration for existing users', () {
    test('an undated local decision is kept and uploaded', () async {
      // What every current install looks like: consentGiven true in prefs,
      // no timestamp, nothing in the cloud.
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,'
            '"consentRecord":{"signatureName":"Sohail",'
            '"signedAt":"2025-11-01T00:00:00.000Z"}}',
      });

      final cloud = FakeCloud(owner: owner(), pets: [pet('p1')]);
      final pets = PetInfoProvider(service: cloud);

      expect(await landingAfterStartup(pets), AppRoutes.home);
      expect(pets.consentGiven, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(cloud.consentWrites, 1);
      expect(cloud.consent?.given, isTrue);
      expect(cloud.consent?.record?.signatureName, 'Sohail');
    });

    test('migration is idempotent across two launches', () async {
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true}',
      });

      final cloud = FakeCloud(owner: owner(), pets: [pet('p1')]);
      await landingAfterStartup(PetInfoProvider(service: cloud));
      await Future<void>.delayed(Duration.zero);

      final writesAfterFirst = cloud.consentWrites;
      final relaunched = PetInfoProvider(service: cloud);
      expect(await landingAfterStartup(relaunched), AppRoutes.home);
      await Future<void>.delayed(Duration.zero);

      expect(relaunched.consentGiven, isTrue);
      expect(cloud.consentWrites, writesAfterFirst);
    });
  });

  group('multiple pets', () {
    test('every pet is restored and none is duplicated', () async {
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,'
            '"consentUpdatedAt":"2026-01-03T00:00:00.000Z",'
            '"consentRecord":{"signatureName":"Sohail",'
            '"signedAt":"2026-01-03T00:00:00.000Z"}}',
      });

      final cloud = FakeCloud(
        consent: signed(),
        owner: owner(),
        pets: [pet('p1'), pet('p2', name: 'Mia'), pet('p3', name: 'Rex')],
      );

      final pets = PetInfoProvider(service: cloud);
      expect(await landingAfterStartup(pets), AppRoutes.home);

      expect(pets.pets.length, 3);
      expect(pets.pets.map((p) => p.id).toSet().length, 3);
      expect(pets.activePet, isNotNull);
    });

    test('a locally added pet survives the restore and is queued', () async {
      final cloud = FakeCloud(consent: signed(), owner: owner());
      final pets = PetInfoProvider(service: cloud);
      await pets.init();
      await pets.addPet(pet('local-1', name: 'Nala'));

      expect(await landingAfterStartup(pets), AppRoutes.home);
      await Future<void>.delayed(Duration.zero);

      expect(pets.pets.map((p) => p.name), contains('Nala'));
      expect(cloud.pets.map((p) => p.id), contains('local-1'));
    });
  });
}
