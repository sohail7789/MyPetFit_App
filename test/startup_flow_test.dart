import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/models/consent_state.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/services/sync_reconciler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Succeeds without touching Firestore.
class _QuietPets extends PetInfoProvider {
  @override
  Future<void> loadConsentFromFirestore() async {}

  @override
  Future<void> loadOwnerFromFirestore() async {}

  @override
  Future<void> loadPetsFromFirestore() async {}
}

class _QuietQuiz extends QuizProvider {
  @override
  Future<void> loadAssessmentsFromFirestore() async {}
}

/// A pets provider whose cloud load blows up — standing in for being offline.
class _OfflinePets extends _QuietPets {
  @override
  Future<void> loadOwnerFromFirestore() async =>
      throw Exception('no connection');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppStartupProvider', () {
    test('runs once, then refuses to run again', () async {
      final startup = AppStartupProvider();
      final pets = _QuietPets();
      final quiz = _QuietQuiz();

      expect(startup.stage, StartupStage.idle);
      await startup.initialize(petInfo: pets, quiz: quiz);
      expect(startup.stage, StartupStage.ready);

      // Landing on the startup screen twice for one sign-in must not reload.
      await startup.initialize(petInfo: pets, quiz: quiz);
      expect(startup.stage, StartupStage.ready);
    });

    test('a failed load lands on failed, not stuck on loading', () async {
      final startup = AppStartupProvider();
      await startup.initialize(petInfo: _OfflinePets(), quiz: _QuietQuiz());

      // Before this the throw escaped and left the stage on `loading`
      // forever, and the router waits on that stage — the app froze.
      expect(startup.stage, StartupStage.failed);
      expect(startup.hasFailed, isTrue);
      expect(startup.error, isNotNull);
    });

    test('a failure can be retried, unlike a success', () async {
      final startup = AppStartupProvider();
      await startup.initialize(petInfo: _OfflinePets(), quiz: _QuietQuiz());
      expect(startup.stage, StartupStage.failed);

      // Same provider, connection back: the retry is allowed through.
      await startup.initialize(petInfo: _QuietPets(), quiz: _QuietQuiz());
      expect(startup.stage, StartupStage.ready);
    });

    test('reset lets the next account load its own data', () async {
      final startup = AppStartupProvider();
      await startup.initialize(petInfo: _QuietPets(), quiz: _QuietQuiz());
      expect(startup.isReady, isTrue);

      // Signing out without this left the stage on `ready`, so the next
      // person's initialize() returned immediately and their pets, owner
      // and assessments were never fetched.
      startup.reset();
      expect(startup.stage, StartupStage.idle);

      var loaded = false;
      final next = _RecordingPets(() => loaded = true);
      await startup.initialize(petInfo: next, quiz: _QuietQuiz());
      expect(loaded, isTrue);
    });

    test('notifies on every stage change so the router re-evaluates',
        () async {
      final startup = AppStartupProvider();
      var notifications = 0;
      startup.addListener(() => notifications++);

      await startup.initialize(petInfo: _QuietPets(), quiz: _QuietQuiz());

      // loading, then ready.
      expect(notifications, 2);
    });
  });

  group('consent survives a sign-out', () {
    // The bug this group pins down: consent lived only in SharedPreferences
    // and was never written to Firestore, so sign-out cleared it and the
    // router's first gate sent every returning user back to /consent with
    // their owner and pets already restored around them.

    test('giving consent stamps it, and the stamp survives a reload', () async {
      final pets = _QuietPets();
      await pets.init();

      await pets.giveConsent(signatureName: 'Sohail');
      expect(pets.consentGiven, isTrue);
      expect(pets.consentUpdatedAt, isNotNull);

      // A second provider over the same prefs — a relaunch.
      final relaunched = _QuietPets();
      await relaunched.init();
      expect(relaunched.consentGiven, isTrue);
      expect(relaunched.consentUpdatedAt, pets.consentUpdatedAt);
      expect(relaunched.consentRecord?.signatureName, 'Sohail');
    });

    test('a device with no local decision adopts the account\'s', () {
      // Signing in after a sign-out, on a reinstall, or on a second handset:
      // local consent is absent, not `false`, so the cloud copy is adopted
      // rather than being argued with.
      final cloud = ConsentState(
        given: true,
        record: ConsentRecord(
          signatureName: 'Sohail',
          signedAt: DateTime.utc(2026, 1, 4),
        ),
        updatedAt: DateTime.utc(2026, 1, 4),
      );

      final outcome = reconcileSingle<ConsentState>(
        local: null,
        cloud: cloud,
        updatedAtOf: (c) => c.updatedAt,
        sameContent: (a, b) => a.sameContentAs(b),
        id: 'consent',
      );

      expect(outcome.resolved.single.given, isTrue);
      expect(outcome.outcomes['consent'], SyncOutcome.adopted);
      expect(outcome.toUpload, isEmpty);

      // The adopted decision is what keeps the assessment routes open — the
      // landing itself no longer consults consent at all.
      expect(
        AppRoutes.landingFor(hasOwner: true, hasPet: true),
        AppRoutes.home,
      );
    });

    test('consent recorded before syncing existed is uploaded, not lost', () {
      // The migration case. An undated local decision has no dated cloud copy
      // to lose to, so it is kept and queued.
      final local = ConsentState(given: true, updatedAt: kUnknownUpdatedAt);

      final outcome = reconcileSingle<ConsentState>(
        local: local,
        cloud: null,
        updatedAtOf: (c) => c.updatedAt,
        sameContent: (a, b) => a.sameContentAs(b),
        id: 'consent',
      );

      expect(outcome.resolved.single.given, isTrue);
      expect(outcome.toUpload.single.given, isTrue);
    });
  });

  group('startup restores everything landingFor reads', () {
    test('the local cache is read before the cloud is reconciled', () async {
      // main() only kicks off init(); it is never awaited there. A reconciler
      // that beat it persisted the whole snapshot from an empty provider,
      // writing `consentGiven: false` over the stored `true` — after which
      // every launch really did open on the consent screen.
      SharedPreferences.setMockInitialValues({
        'pet_info_state': '{"pets":[],"activePetIndex":0,'
            '"consentGiven":true,"consentUpdatedAt":"2026-01-04T00:00:00.000Z"}',
      });

      final pets = _OrderedPets();
      await AppStartupProvider()
          .initialize(petInfo: pets, quiz: _QuietQuiz());

      expect(pets.wasLoadedBeforeCloudRead, isTrue);
      expect(pets.consentGiven, isTrue);
    });

    test('consent is restored before the stage reports ready', () async {
      final startup = AppStartupProvider();
      final pets = _OrderedPets();

      await startup.initialize(petInfo: pets, quiz: _QuietQuiz());

      // The router reads consent the instant this flips, so a consent load
      // that happened afterwards would be a load the redirect never sees.
      expect(pets.consentWasRead, isTrue);
      expect(startup.isReady, isTrue);
    });
  });

  group('landing decision', () {
    // The real function the redirect calls. What matters is the order:
    // owner, then pet, then the app. Consent is no longer part of it — it
    // gates the routes that collect data, not the way in.
    test('a brand-new account starts at owner details', () {
      expect(
        AppRoutes.landingFor(hasOwner: false, hasPet: false),
        AppRoutes.ownerInfo,
      );
    });

    test('owner but no pet goes to the pet form', () {
      expect(
        AppRoutes.landingFor(hasOwner: true, hasPet: false),
        AppRoutes.petInfo,
      );
    });

    test('a fully set-up returning user goes straight home', () {
      // The old sign-in screen sent everyone to /consent regardless, so a
      // returning user was walked back through a step they had finished.
      expect(
        AppRoutes.landingFor(hasOwner: true, hasPet: true),
        AppRoutes.home,
      );
    });

    test('consent never appears in a landing decision', () {
      // The complaint that produced this change: signing in must not put
      // anyone in front of the consent form. No combination can any more.
      for (final hasOwner in [false, true]) {
        for (final hasPet in [false, true]) {
          expect(
            AppRoutes.landingFor(hasOwner: hasOwner, hasPet: hasPet),
            isNot(AppRoutes.consent),
            reason: 'owner=$hasOwner pet=$hasPet landed on the consent form',
          );
        }
      }
    });

    test('every destination is a fixed point — the redirect cannot loop', () {
      // The redirect only computes a landing while the user sits on an entry
      // route (a public one, or /startup). So a loop is possible only if
      // landingFor could return an entry route, which would be re-evaluated
      // and land somewhere again. Exhausting the input space proves it
      // cannot: four combinations, none returning an entry route.
      const entryRoutes = {
        AppRoutes.welcome,
        AppRoutes.onboarding,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
        AppRoutes.startup,
      };

      for (final hasOwner in [false, true]) {
        for (final hasPet in [false, true]) {
          final destination =
              AppRoutes.landingFor(hasOwner: hasOwner, hasPet: hasPet);
          expect(
            entryRoutes.contains(destination),
            isFalse,
            reason: 'owner=$hasOwner pet=$hasPet landed back on the entry '
                'route $destination, which would be redirected again',
          );
        }
      }
    });
  });
}

/// Reports whether the cloud load was reached.
class _RecordingPets extends _QuietPets {
  _RecordingPets(this.onLoad);

  final void Function() onLoad;

  @override
  Future<void> loadOwnerFromFirestore() async => onLoad();
}

/// Records what startup had already done by the time it reached the cloud.
class _OrderedPets extends _QuietPets {
  bool consentWasRead = false;
  bool wasLoadedBeforeCloudRead = false;

  @override
  Future<void> loadConsentFromFirestore() async {
    consentWasRead = true;
    wasLoadedBeforeCloudRead = isLoaded;
  }
}