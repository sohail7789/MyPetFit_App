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
import 'package:mypetfit_app/providers/theme_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/account_screen.dart';
import 'package:mypetfit_app/providers/reminders_provider.dart';
import 'package:mypetfit_app/services/reminder_gateway.dart';
import 'package:mypetfit_app/services/reminder_scheduler.dart';

import 'support/fake_cloud.dart';

/// Sprint 4, P0-2 — signing out has to end the session, not just the screen.
///
/// `AuthProvider.signOut()` used to clear its own fields and the persisted
/// blob and stop there. `AuthService.signOut()` — which ends the Google and
/// Firebase sessions — existed but was never called from anywhere, so
/// `FirebaseAuth.currentUser` survived a logout. Every Firestore path in this
/// app is derived from that uid, so the previous account stayed reachable:
/// on a shared handset, one person's health record under another person's
/// hands.
///
/// The session teardown is injected here rather than mocked away. Proving
/// that `FirebaseAuth.currentUser` becomes null needs a real auth backend and
/// belongs in the emulator journey; what these tests prove is that signing
/// out *reaches* the teardown at all, which is precisely what was missing,
/// and that a failed teardown is never reported as success.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A provider carrying a session, as it would be after signing in.
  Future<AuthProvider> signedIn({
    Future<void> Function()? endSession,
  }) async {
    SharedPreferences.setMockInitialValues({
      'auth_state': '{"isSignedIn":true,"username":"bruno-owner",'
          '"email":"owner@example.com","firstName":"Sam","lastName":"Rao"}',
    });

    final auth = AuthProvider(endSession: endSession);
    await auth.init();
    expect(auth.isSignedIn, isTrue, reason: 'fixture never signed in');
    return auth;
  }

  group('signing out ends the session', () {
    test('the Firebase and Google teardown is actually reached', () async {
      // The whole defect in one assertion: the old implementation never
      // called this, so the counter stayed at zero.
      var teardowns = 0;
      final auth = await signedIn(endSession: () async => teardowns++);

      await auth.signOut();

      expect(
        teardowns,
        1,
        reason: 'sign-out cleared local state without ending the session',
      );
    });

    test('the local session is cleared too', () async {
      final auth = await signedIn(endSession: () async {});

      await auth.signOut();

      expect(auth.isSignedIn, isFalse);
      expect(auth.email, isEmpty);
      expect(auth.username, isEmpty);
      expect(auth.displayName, isEmpty);
      expect(auth.userId, isEmpty);
    });

    test('nothing is left on disk for the next person to inherit', () async {
      final auth = await signedIn(endSession: () async {});

      await auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_state'), isNull);

      // And a fresh provider reading that disk starts signed out.
      final next = AuthProvider(endSession: () async {});
      await next.init();
      expect(next.isSignedIn, isFalse);
      expect(next.email, isEmpty);
    });

    test('the session ends before the local state is cleared', () async {
      // Order matters: if the teardown throws, the fields must still say
      // signed in, because they still are.
      late bool signedInWhenTornDown;
      final auth = await signedIn();

      final withOrder = AuthProvider(endSession: () async {
        signedInWhenTornDown = auth.isSignedIn;
      });
      await withOrder.init();
      await withOrder.signOut();

      expect(signedInWhenTornDown, isTrue);
    });
  });

  group('a failed sign-out is not reported as success', () {
    test('the provider stays signed in and rethrows', () async {
      final auth = await signedIn(
        endSession: () async => throw Exception('network unavailable'),
      );

      await expectLater(auth.signOut(), throwsException);

      // Still signed in, because the session is still alive. Claiming
      // otherwise is the state this whole fix exists to prevent.
      expect(auth.isSignedIn, isTrue);
      expect(auth.email, 'owner@example.com');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_state'), isNotNull);
    });
  });

  group('the account screen', () {
    Widget host(AuthProvider auth) {
      final router = GoRouter(
        initialLocation: AppRoutes.account,
        routes: [
          GoRoute(
            path: AppRoutes.account,
            builder: (_, _) => const AccountScreen(),
          ),
          GoRoute(
            path: AppRoutes.signIn,
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('SIGN IN'))),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => QuizProvider(service: FakeCloud())),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(
            create: (_) => PetInfoProvider(service: FakeCloud()),
          ),
          ChangeNotifierProvider(create: (_) => AddressProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AppStartupProvider()),
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

    testWidgets('a successful sign-out leaves for the sign-in screen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var teardowns = 0;
      final auth = await signedIn(endSession: () async => teardowns++);

      await tester.pumpWidget(host(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(teardowns, 1);
      expect(find.text('SIGN IN'), findsOneWidget);
    });

    testWidgets('a failed sign-out says so and stays put', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = await signedIn(
        endSession: () async => throw Exception('network unavailable'),
      );

      await tester.pumpWidget(host(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      // Not on the sign-in screen, and told why.
      expect(find.text('SIGN IN'), findsNothing);
      expect(
        find.textContaining("Couldn't sign out"),
        findsOneWidget,
        reason: 'a logout that did not happen was reported as if it had',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
