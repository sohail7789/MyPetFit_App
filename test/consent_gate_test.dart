import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/screens/consent/consent_screen.dart';

import 'support/fake_cloud.dart';

/// Consent gates the routes that collect data — not signing in.
///
/// Reported after the persistence fix shipped: signing in with Google still
/// opened the consent form. It opened for email sign-in too, because consent
/// led `landingFor`, so every route in was funnelled through it. Consent is a
/// route guard now: asked for when a pet is created or an assessment starts,
/// and never on the way in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('which routes are gated', () {
    test('creating a pet or starting an assessment needs consent', () {
      expect(AppRoutes.requiresConsent(AppRoutes.petInfo), isTrue);
      expect(AppRoutes.requiresConsent(AppRoutes.addPet), isTrue);
      expect(AppRoutes.requiresConsent(AppRoutes.quiz), isTrue);
    });

    test('signing in and the app itself do not', () {
      // The reported complaint, stated as a rule.
      for (final route in [
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.welcome,
        AppRoutes.startup,
        AppRoutes.home,
        AppRoutes.ownerInfo,
        AppRoutes.shop,
        AppRoutes.account,
        AppRoutes.reportHistory,
        AppRoutes.report,
      ]) {
        expect(
          AppRoutes.requiresConsent(route),
          isFalse,
          reason: '$route should not stand behind the consent form',
        );
      }
    });

    test('editing a saved pet is not gated', () {
      // The pet already exists, so consent was given for it at some point.
      // Re-asking to change its weight would be the old bug in miniature.
      expect(AppRoutes.requiresConsent(AppRoutes.petEdit(0)), isFalse);
      expect(AppRoutes.requiresConsent(AppRoutes.petProfile(0)), isFalse);
    });

    test('the form itself is not gated, so the guard cannot loop', () {
      expect(AppRoutes.requiresConsent(AppRoutes.consent), isFalse);
    });
  });

  group('resuming what was gated', () {
    test('the destination travels with the redirect', () {
      final target = AppRoutes.consentThen(AppRoutes.quiz);

      expect(target, startsWith(AppRoutes.consent));
      expect(Uri.parse(target).queryParameters['next'], AppRoutes.quiz);
    });

    test('a path with its own query survives the round trip', () {
      final target = AppRoutes.consentThen('/pet-info?mode=add');

      expect(Uri.parse(target).queryParameters['next'], '/pet-info?mode=add');
    });
  });

  group('the consent screen honours it', () {
    Widget host({String? next}) {
      final pets = PetInfoProvider(service: FakeCloud());
      final router = GoRouter(
        initialLocation: next == null
            ? AppRoutes.consent
            : AppRoutes.consentThen(next),
        routes: [
          GoRoute(
            path: AppRoutes.consent,
            builder: (_, state) =>
                ConsentScreen(next: state.uri.queryParameters['next']),
          ),
          for (final path in [AppRoutes.petInfo, AppRoutes.quiz])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Center(child: Text(path))),
            ),
        ],
      );

      return ChangeNotifierProvider.value(
        value: pets,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
    }

    Future<void> sign(WidgetTester tester) async {
      await tester
          .tap(find.text('I have read and agree to the consent above.'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Sohail Inamdar');
      await tester.pump();
      await tester.tap(find.text('Agree & Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('signing resumes the route that was gated', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(next: AppRoutes.quiz));
      await tester.pump();
      await sign(tester);

      expect(find.text(AppRoutes.quiz), findsOneWidget);
    });

    testWidgets('with no destination it continues the first run',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host());
      await tester.pump();
      await sign(tester);

      expect(find.text(AppRoutes.petInfo), findsOneWidget);
    });
  });
}
