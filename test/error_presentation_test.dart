import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/address_provider.dart';
import 'package:mypetfit_app/providers/app_startup_provider.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/product_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/screens/account/account_screen.dart';
import 'package:mypetfit_app/screens/account/delete_account_screen.dart';
import 'package:mypetfit_app/services/account_deletion.dart';
import 'package:mypetfit_app/services/auth_service.dart'
    show ReauthenticationRequired;
import 'package:mypetfit_app/services/crash_reporter.dart';
import 'package:mypetfit_app/providers/reminders_provider.dart';
import 'package:mypetfit_app/services/reminder_gateway.dart';
import 'package:mypetfit_app/services/reminder_scheduler.dart';

import 'support/fake_cloud.dart';
import 'support/product_fixtures.dart';

/// Sprint 4, P1 error/logging audit — what the user is told, and what the
/// developer gets instead.
///
/// Several failure paths interpolated the caught exception straight into a
/// snackbar. A `FirebaseException` or `PlatformException` rendered that way
/// carries project identifiers, plugin internals and temporary file paths —
/// none of it actionable, some of it nobody's business. The exception belongs
/// in diagnostics; the user gets a sentence they can do something about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(CrashReporter.uninstall);

  /// The shape of a real platform failure: a message full of things that
  /// should never reach a snackbar.
  final leaky = Exception(
    'PlatformException(channel-error, project mypetfit-c530e, '
    '/var/mobile/Containers/Data/Application/tmp/report.pdf, null)',
  );

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Asserts nothing internal made it onto the screen.
  void expectNoLeak(WidgetTester tester) {
    for (final fragment in const [
      'PlatformException',
      'mypetfit-c530e',
      '/var/mobile',
      'Exception:',
      'channel-error',
    ]) {
      expect(
        find.textContaining(fragment),
        findsNothing,
        reason: '"$fragment" was shown to the user',
      );
    }
  }

  Widget host(Widget screen, {required String initial, AuthProvider? auth}) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: initial, builder: (_, _) => screen),
        for (final path in [
          AppRoutes.signIn,
          AppRoutes.account,
          AppRoutes.accountDeleted,
        ])
          if (path != initial)
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Center(child: Text(path))),
            ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: auth ?? AuthProvider(endSession: () async {}),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(service: FakeCloud()),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => PetInfoProvider(service: FakeCloud()),
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => AppStartupProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Signing out cancels any pending retake reminder and clears the
        // preference, so the screen needs both in scope.
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        Provider<ReminderScheduler>(
          create: (_) => ReminderScheduler(const NoopReminderGateway()),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  group('a failed sign-out', () {
    testWidgets('says something useful and leaks nothing', (tester) async {
      sizeUp(tester);
      SharedPreferences.setMockInitialValues({
        'auth_state': '{"isSignedIn":true,"username":"owner",'
            '"email":"owner@example.com","firstName":"Sam","lastName":"Rao"}',
      });

      final auth = AuthProvider(endSession: () async => throw leaky);
      await auth.init();

      await tester.pumpWidget(
        host(const AccountScreen(), initial: AppRoutes.account, auth: auth),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't sign out. Please try again."), findsOneWidget);
      expectNoLeak(tester);
    });

    testWidgets('reaches diagnostics with the original exception',
        (tester) async {
      sizeUp(tester);
      SharedPreferences.setMockInitialValues({
        'auth_state': '{"isSignedIn":true,"username":"owner",'
            '"email":"owner@example.com","firstName":"Sam","lastName":"Rao"}',
      });

      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      final auth = AuthProvider(endSession: () async => throw leaky);
      await auth.init();

      await tester.pumpWidget(
        host(const AccountScreen(), initial: AppRoutes.account, auth: auth),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(sink.errors, hasLength(1));
      expect(sink.errors.single.error, same(leaky));
      expect(
        sink.errors.single.fatal,
        isFalse,
        reason: 'the app recovered and said so — this is not a crash',
      );
    });
  });

  group('a failed account deletion', () {
    Future<void> confirmAndDelete(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();
    }

    testWidgets('says what is true and leaks nothing', (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(
        DeleteAccountScreen(deletion: _FailingDeletion(leaky)),
        initial: AppRoutes.deleteAccount,
      ));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      expect(
        find.textContaining('Your account was not deleted'),
        findsOneWidget,
      );
      expectNoLeak(tester);
    });

    testWidgets('a destructive failure reaches diagnostics', (tester) async {
      sizeUp(tester);
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      await tester.pumpWidget(host(
        DeleteAccountScreen(deletion: _FailingDeletion(leaky)),
        initial: AppRoutes.deleteAccount,
      ));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      expect(sink.errors, hasLength(1));
      expect(sink.errors.single.error, same(leaky));
    });

    testWidgets('a wrong password still says so, without the prefix',
        (tester) async {
      // The counter-case: these messages are written by AuthService for the
      // user, so they must keep reaching them — just not wearing "Exception:".
      sizeUp(tester);

      await tester.pumpWidget(host(
        DeleteAccountScreen(
          deletion: _StaleSessionDeletion(
            Exception('That password is not correct.'),
          ),
        ),
        initial: AppRoutes.deleteAccount,
      ));
      await tester.pumpAndSettle();
      await confirmAndDelete(tester);

      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('That password is not correct.'), findsOneWidget);
      expect(find.textContaining('Exception:'), findsNothing);
    });
  });

  group('the catalog', () {
    test('keeps its failure as a flag and reports nothing', () async {
      // A shop that will not load is an ordinary offline condition with a
      // retry on screen. It must not fill Crashlytics, and it must not print
      // the whole catalog into release logs — which is what it used to do.
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      final catalog = ProductProvider(
        service: FakeCatalogService(const [], error: leaky),
      );
      await catalog.loadProducts();

      expect(catalog.error, isNotNull, reason: 'the shop cannot tell it failed');
      expect(catalog.products, isEmpty);
      expect(catalog.loading, isFalse);
      expect(sink.errors, isEmpty);
    });
  });
}

typedef _Recorded = ({Object error, StackTrace? stack, bool fatal});

class _RecordingSink implements CrashSink {
  final errors = <_Recorded>[];

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false}) async {
    errors.add((error: error, stack: stack, fatal: fatal));
  }
}

class _FailingDeletion extends AccountDeletion {
  final Object failure;
  const _FailingDeletion(this.failure);

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async => throw failure;

  @override
  Future<void> deleteAccount() async {}
}

class _StaleSessionDeletion extends AccountDeletion {
  final Object reauthFailure;
  const _StaleSessionDeletion(this.reauthFailure);

  @override
  String? get providerId => 'password';

  @override
  Future<void> deleteUserData() async {}

  @override
  Future<void> deleteAccount() async => throw const ReauthenticationRequired();

  @override
  Future<void> reauthenticateWithPassword(String password) async =>
      throw reauthFailure;
}
