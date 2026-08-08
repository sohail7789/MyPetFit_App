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
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  group('the sign-in screen', () {
    testWidgets('offers Google and Apple, both wired', (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(wiring(tester), {'Google': true, 'Apple': true});
    });
  });

  group('the sign-up screen', () {
    testWidgets('offers Google and Apple, both wired', (tester) async {
      sizeUp(tester);

      await tester.pumpWidget(host(const SignUpScreen()));
      await tester.pumpAndSettle();

      // Both were previously handler-less: the fastest-looking way into the
      // app did nothing at all.
      expect(wiring(tester), {'Google': true, 'Apple': true});
    });
  });

  group('Apple is offered wherever Google is', () {
    // The App Store rule in one assertion. If Google is ever added to another
    // entry point without Apple beside it, this is what catches it.
    for (final entry in {
      'sign in': const SignInScreen(),
      'sign up': const SignUpScreen(),
    }.entries) {
      testWidgets('on ${entry.key}', (tester) async {
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
    }
  });
}
