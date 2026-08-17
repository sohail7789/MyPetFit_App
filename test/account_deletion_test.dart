import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/screens/account/delete_account_screen.dart';
import 'package:mypetfit_app/services/account_deletion.dart';
import 'package:mypetfit_app/providers/reminders_provider.dart';
import 'package:mypetfit_app/services/reminder_gateway.dart';
import 'package:mypetfit_app/services/reminder_scheduler.dart';
import 'package:mypetfit_app/services/auth_service.dart'
    show ReauthenticationRequired;

import 'support/fake_cloud.dart';

/// Sprint 4, P0-1 — "Account deleted" has to be true when it is said.
///
/// The screen used to clear the local providers, sign out, and announce that
/// the account was gone. The Firebase account and every document under
/// `users/{uid}` stayed exactly where they were. That is a false statement to
/// someone about their own health records, and it fails the deletion
/// requirements of both stores.
///
/// These tests are about the two halves of that promise: the deletion really
/// happens, and when it does not, the app says so instead of claiming
/// success.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PetInfo pet(String id, String name) => PetInfo(
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

  ScoreResult report(int percent, String petId) => ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: HealthCategory.good,
        categoryScores: const {'Skin & Coat': 55},
        completedAt: DateTime.now(),
        petId: petId,
      );

  /// Records what the screen asked for, and in what order.
  ///
  /// Order is the part that matters: the documents are reachable only while
  /// the account exists, so deleting the account first would strand them.
  late List<String> steps;

  Widget host(AccountDeletion deletion, {FakeCloud? cloud}) {
    final router = GoRouter(
      initialLocation: AppRoutes.deleteAccount,
      routes: [
        GoRoute(
          path: AppRoutes.deleteAccount,
          builder: (_, _) => DeleteAccountScreen(deletion: deletion),
        ),
        GoRoute(
          path: AppRoutes.accountDeleted,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('DELETED'))),
        ),
        GoRoute(
          path: AppRoutes.account,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('ACCOUNT'))),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuizProvider(service: cloud ?? FakeCloud()),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => PetInfoProvider(service: cloud ?? FakeCloud()),
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(endSession: () async {})),
        ChangeNotifierProvider(create: (_) => AppStartupProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Deleting the account cancels any pending retake reminder and
        // clears the preference, so the screen needs both in scope.
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        Provider<ReminderScheduler>(
          create: (_) => ReminderScheduler(const NoopReminderGateway()),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<void> confirmAndDelete(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  setUp(() => steps = []);

  group('a successful deletion', () {
    testWidgets('deletes the data, then the account, then confirms',
        (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(_RecordingDeletion(steps)));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // Both happened, and in the only order that leaves nothing stranded.
      expect(steps, ['deleteUserData', 'deleteAccount']);
      expect(find.text('DELETED'), findsOneWidget);
    });

    testWidgets('every stored document is gone', (tester) async {
      sizeUp(tester);
      // A real cascade over a fake cloud: two pets, each with reports, plus
      // the owner profile and the consent record.
      final cloud = FakeCloud(
        pets: [pet('p1', 'Bruno'), pet('p2', 'Mia')],
        assessments: {
          'p1': [report(70, 'p1')],
          'p2': [report(40, 'p2')],
        },
      );

      await tester.pumpWidget(host(_CloudDeletion(cloud, steps), cloud: cloud));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      expect(cloud.userDataDeletions, 1);
      expect(cloud.pets, isEmpty, reason: 'pets survived the deletion');
      expect(cloud.assessments, isEmpty,
          reason: 'health records survived the deletion');
      expect(cloud.owner, isNull);
      expect(cloud.consent, isNull);
      expect(find.text('DELETED'), findsOneWidget);
    });

    testWidgets('the device is cleared only after the account is gone',
        (tester) async {
      sizeUp(tester);
      SharedPreferences.setMockInitialValues({
        'auth_state': '{"isSignedIn":true,"username":"owner",'
            '"email":"owner@example.com","firstName":"Sam","lastName":"Rao"}',
      });

      await tester.pumpWidget(host(_RecordingDeletion(steps)));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_state'), isNull);
      expect(find.text('DELETED'), findsOneWidget);
    });
  });

  group('a failed deletion is never announced as success', () {
    testWidgets('a failure to remove the data stops everything',
        (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(_FailingDeletion(steps, failOn: 'data')));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // The account was never touched, and the user was told the truth.
      expect(steps, ['deleteUserData']);
      expect(find.text('DELETED'), findsNothing);
      expect(
        find.textContaining('Your account was not deleted'),
        findsOneWidget,
        reason: 'a deletion that failed was reported as if it had worked',
      );
    });

    testWidgets('a failure to remove the account stops everything',
        (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(_FailingDeletion(steps, failOn: 'account')));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      expect(find.text('DELETED'), findsNothing);
      expect(find.textContaining('Your account was not deleted'), findsOneWidget);
    });

    testWidgets('the local session survives a failed deletion', (tester) async {
      sizeUp(tester);
      SharedPreferences.setMockInitialValues({
        'auth_state': '{"isSignedIn":true,"username":"owner",'
            '"email":"owner@example.com","firstName":"Sam","lastName":"Rao"}',
      });

      await tester.pumpWidget(host(_FailingDeletion(steps, failOn: 'account')));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // The account still exists, so the device must still be signed in to it.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_state'), isNotNull);
    });
  });

  group('a stale session', () {
    testWidgets('is refreshed by password, then the deletion completes',
        (tester) async {
      sizeUp(tester);
      final deletion = _StaleSessionDeletion(steps, providerId: 'password');

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // Firebase refused the first attempt, so the app asked who they are.
      expect(find.text('Confirm your password'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'correct horse');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(steps, [
        'deleteUserData',
        'deleteAccount',
        'reauthenticateWithPassword',
        'deleteAccount',
      ]);
      expect(find.text('DELETED'), findsOneWidget);
    });

    testWidgets('is refreshed through Google for a Google account',
        (tester) async {
      sizeUp(tester);
      final deletion = _StaleSessionDeletion(steps, providerId: 'google.com');

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // No password box for an account that never had a password.
      expect(find.text('Confirm your password'), findsNothing);
      expect(steps, [
        'deleteUserData',
        'deleteAccount',
        'reauthenticateWithGoogle',
        'deleteAccount',
      ]);
      expect(find.text('DELETED'), findsOneWidget);
    });

    // Apple accounts reached the password prompt and could not answer it, so
    // the one group Apple *requires* to be able to delete themselves were the
    // only ones who could not. The service method existed and was correct —
    // nothing chose it.
    testWidgets('is refreshed through Apple for an Apple account',
        (tester) async {
      sizeUp(tester);
      final deletion = _StaleSessionDeletion(steps, providerId: 'apple.com');

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      // The defect, stated directly: an Apple account has no password, so
      // being asked for one is a dead end.
      expect(find.text('Confirm your password'), findsNothing);
      expect(steps, [
        'deleteUserData',
        'deleteAccount',
        'reauthenticateWithApple',
        'deleteAccount',
      ]);
      expect(find.text('DELETED'), findsOneWidget);
    });

    testWidgets('cancelling the prompt leaves the account alone',
        (tester) async {
      sizeUp(tester);
      final deletion = _StaleSessionDeletion(steps, providerId: 'password');

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(steps, ['deleteUserData', 'deleteAccount']);
      expect(find.text('DELETED'), findsNothing);
      // And the screen is usable again rather than stuck mid-deletion.
      expect(find.text('Delete my account'), findsOneWidget);
    });

    testWidgets('a wrong password does not delete the account',
        (tester) async {
      sizeUp(tester);
      final deletion = _StaleSessionDeletion(
        steps,
        providerId: 'password',
        reauthFails: true,
      );

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(steps.where((s) => s == 'deleteAccount').length, 1,
          reason: 'the account was deleted despite a failed confirmation');
      expect(find.text('DELETED'), findsNothing);
    });
  });

  group('the button', () {
    testWidgets('does nothing until DELETE is typed', (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(_RecordingDeletion(steps)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(steps, isEmpty);
      expect(find.text('DELETED'), findsNothing);
    });

    testWidgets('cannot be pressed twice into a half-deleted account',
        (tester) async {
      sizeUp(tester);
      final deletion = _SlowDeletion(steps);

      await tester.pumpWidget(host(deletion));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete my account'));
      await tester.pump();

      // Mid-flight the control reports itself busy and refuses a second press.
      expect(find.text('Deleting your account…'), findsOneWidget);
      await tester.tap(find.text('Deleting your account…'));
      await tester.pump();

      deletion.release();
      await tester.pumpAndSettle();

      expect(steps.where((s) => s == 'deleteUserData').length, 1);
    });
  });
}

/// Records the sequence without touching Firebase.
class _RecordingDeletion extends AccountDeletion {
  final List<String> steps;
  const _RecordingDeletion(this.steps);

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async => steps.add('deleteUserData');

  @override
  Future<void> deleteAccount() async => steps.add('deleteAccount');
}

/// Runs the real cascade against the fake cloud.
class _CloudDeletion extends AccountDeletion {
  final FakeCloud cloud;
  final List<String> steps;
  const _CloudDeletion(this.cloud, this.steps);

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async {
    steps.add('deleteUserData');
    await cloud.deleteAllUserData();
  }

  @override
  Future<void> deleteAccount() async => steps.add('deleteAccount');
}

class _FailingDeletion extends AccountDeletion {
  final List<String> steps;
  final String failOn;
  const _FailingDeletion(this.steps, {required this.failOn});

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async {
    steps.add('deleteUserData');
    if (failOn == 'data') throw Exception('network unavailable');
  }

  @override
  Future<void> deleteAccount() async {
    steps.add('deleteAccount');
    if (failOn == 'account') throw Exception('network unavailable');
  }
}

/// Refuses the first deletion the way Firebase refuses a stale session.
class _StaleSessionDeletion extends AccountDeletion {
  final List<String> steps;
  final String _providerId;
  final bool reauthFails;

  const _StaleSessionDeletion(
    this.steps, {
    required String providerId,
    this.reauthFails = false,
  }) : _providerId = providerId;

  @override
  String? get providerId => _providerId;

  @override
  Future<void> deleteUserData() async => steps.add('deleteUserData');

  @override
  Future<void> deleteAccount() async {
    final first = !steps.contains('deleteAccount');
    steps.add('deleteAccount');
    if (first) throw const ReauthenticationRequired();
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    steps.add('reauthenticateWithPassword');
    if (reauthFails) throw Exception('That password is not correct.');
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    steps.add('reauthenticateWithGoogle');
    if (reauthFails) throw Exception('Google sign-in was cancelled.');
  }

  @override
  Future<void> reauthenticateWithApple() async {
    steps.add('reauthenticateWithApple');
    if (reauthFails) throw Exception('Apple sign in was cancelled.');
  }
}

/// Holds the deletion open so a second press can be attempted mid-flight.
class _SlowDeletion extends AccountDeletion {
  final List<String> steps;
  _SlowDeletion(this.steps);

  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async {
    steps.add('deleteUserData');
    await _gate.future;
  }

  @override
  Future<void> deleteAccount() async => steps.add('deleteAccount');
}
