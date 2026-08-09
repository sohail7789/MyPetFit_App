import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/locale_provider.dart';
import 'package:mypetfit_app/screens/auth/sign_in_screen.dart';
import 'package:mypetfit_app/screens/auth/sign_up_screen.dart';
import 'package:mypetfit_app/widgets/social_buttons.dart';

/// Sprint 4, P0-4 — no authentication control may be decoration.
///
/// The Apple button was rendered on both screens and wired on neither, and
/// the sign-up screen passed no handlers at all, so its Google button was
/// dead too. A reviewer pressing either during App Store review would have
/// found nothing happen — and Guideline 4.8 requires Sign in with Apple to
/// be genuinely offered wherever Google is.
///
/// These assert the property that carries the behaviour, not that a widget is
/// on screen: a control with no callback is exactly the defect, and it looks
/// identical to a working one.
///
/// **Why these are now per-platform.** The same reasoning cuts both ways.
/// Guideline 4.8 is an App Store rule, so it binds on iOS and says nothing
/// about Android — and on Android the Apple button was the very defect this
/// file exists to prevent. `SignInWithApple.getAppleIDCredential` needs
/// `webAuthenticationOptions` off Apple platforms, the app supplies none, so
/// the control threw the moment it was pressed. A button that always fails is
/// decoration with a worse ending.
///
/// So the rule is asserted where it applies and its inverse is asserted where
/// that one applies: Apple beside Google on iOS, and no Apple on Android.
/// Neither guarantee can regress without a failure here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Runs [body] as though the app were on [platform].
  ///
  /// Set and cleared inside the test body rather than in setUp/tearDown:
  /// flutter_test asserts every foundation debug variable is back to null
  /// when the body returns, which is before any tearDown would run.
  Future<void> onPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Widget host(Widget screen) {
    final router = GoRouter(
      initialLocation: '/screen',
      routes: [
        GoRoute(path: '/screen', builder: (_, _) => screen),
        for (final path in [
          AppRoutes.signIn,
          AppRoutes.signUp,
          AppRoutes.home,
          AppRoutes.forgotPassword,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(endSession: () async {}),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Every social control on screen, with whether it would actually do
  /// something when pressed.
  Map<String, bool> wiring(WidgetTester tester) => {
        for (final button in tester.widgetList<SocialButton>(
          find.byType(SocialButton),
        ))
          button.label: button.onPressed != null,
      };

  const screens = {
    'sign in': SignInScreen(),
    'sign up': SignUpScreen(),
  };

  group('on iOS', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} offers Google and Apple, both wired',
          (tester) async {
        await onPlatform(TargetPlatform.iOS, () async {
          sizeUp(tester);

          await tester.pumpWidget(host(entry.value));
          await tester.pumpAndSettle();

          // Both were previously handler-less: the fastest-looking way into
          // the app did nothing at all.
          expect(wiring(tester), {'Google': true, 'Apple': true});
        });
      });
    }
  });

  group('on Android', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} offers Google, and no Apple to fail on',
          (tester) async {
        await onPlatform(TargetPlatform.android, () async {
          sizeUp(tester);

          await tester.pumpWidget(host(entry.value));
          await tester.pumpAndSettle();

          expect(
            wiring(tester),
            {'Google': true},
            reason: 'Sign in with Apple cannot complete on Android without '
                'webAuthenticationOptions, so offering it renders a control '
                'that throws when pressed',
          );
        });
      });
    }
  });

  group('Apple is offered wherever Google is, on iOS', () {
    // The App Store rule in one assertion. If Google is ever added to another
    // entry point without Apple beside it, this is what catches it.
    for (final entry in screens.entries) {
      testWidgets('on ${entry.key}', (tester) async {
        await onPlatform(TargetPlatform.iOS, () async {
          sizeUp(tester);

          await tester.pumpWidget(host(entry.value));
          await tester.pumpAndSettle();

          final wired = wiring(tester);
          expect(
            wired['Google'] == true,
            wired['Apple'] == true,
            reason: 'Guideline 4.8: a third-party login without Sign in with '
                'Apple beside it is an App Store rejection',
          );
        });
      });
    }
  });
}
