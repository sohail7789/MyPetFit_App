import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Succeeds without touching Firestore.
class _QuietPets extends PetInfoProvider {
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

  group('landing decision', () {
    // The real function the redirect calls. What matters is the order:
    // consent, then owner, then pet, then the app.
    test('a brand-new account starts at consent', () {
      expect(
        AppRoutes.landingFor(
          consentGiven: false,
          hasOwner: false,
          hasPet: false,
        ),
        AppRoutes.consent,
      );
    });

    test('consent given but no owner goes to owner details', () {
      expect(
        AppRoutes.landingFor(
          consentGiven: true,
          hasOwner: false,
          hasPet: false,
        ),
        AppRoutes.ownerInfo,
      );
    });

    test('owner but no pet goes to the pet form', () {
      expect(
        AppRoutes.landingFor(
          consentGiven: true,
          hasOwner: true,
          hasPet: false,
        ),
        AppRoutes.petInfo,
      );
    });

    test('a fully set-up returning user goes straight home', () {
      // The old sign-in screen sent everyone to /consent regardless, so a
      // returning user was walked back through a step they had finished.
      expect(
        AppRoutes.landingFor(
          consentGiven: true,
          hasOwner: true,
          hasPet: true,
        ),
        AppRoutes.home,
      );
    });

    test('every destination is a fixed point — the redirect cannot loop', () {
      // The redirect only computes a landing while the user sits on an entry
      // route (a public one, or /startup). So a loop is possible only if
      // landingFor could return an entry route, which would be re-evaluated
      // and land somewhere again. Exhausting the input space proves it
      // cannot: eight combinations, none returning an entry route.
      const entryRoutes = {
        AppRoutes.welcome,
        AppRoutes.onboarding,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
        AppRoutes.verifyCode,
        AppRoutes.resetPassword,
        AppRoutes.startup,
      };

      for (final consentGiven in [false, true]) {
        for (final hasOwner in [false, true]) {
          for (final hasPet in [false, true]) {
            final destination = AppRoutes.landingFor(
              consentGiven: consentGiven,
              hasOwner: hasOwner,
              hasPet: hasPet,
            );
            expect(
              entryRoutes.contains(destination),
              isFalse,
              reason: 'consent=$consentGiven owner=$hasOwner pet=$hasPet '
                  'landed back on the entry route $destination, which would '
                  'be redirected again',
            );
          }
        }
      }
    });

    test('consent outranks the later gates', () {
      // Someone whose consent was withdrawn is asked again before anything
      // else, even with an owner and pets already on file.
      expect(
        AppRoutes.landingFor(
          consentGiven: false,
          hasOwner: true,
          hasPet: true,
        ),
        AppRoutes.consent,
      );
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