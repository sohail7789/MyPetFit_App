import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/data/questions_data.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/account/report_history_screen.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';

/// Starting an assessment must never route through the consent form.
///
/// Consent is a gate the router owns and clears once per account. Sending a
/// retake back through it asked someone who had already signed to sign again,
/// which is the same complaint as the sign-in bug wearing a different hat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PetInfo bruno() => PetInfo(
        id: 'p1',
        name: 'Bruno',
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  /// A stand-in for whichever screen the tap lands on, so the test can name
  /// the destination without building the real quiz.
  Widget marker(String label) => Scaffold(body: Center(child: Text(label)));

  Widget host({
    required Widget screen,
    required String location,
    required QuizProvider quiz,
    required PetInfoProvider pets,
  }) {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: location, builder: (_, _) => screen),
        GoRoute(
          path: AppRoutes.quiz,
          builder: (_, _) => marker('QUIZ'),
        ),
        GoRoute(
          path: AppRoutes.consent,
          builder: (_, _) => marker('CONSENT'),
        ),
        GoRoute(
          path: AppRoutes.report,
          builder: (_, _) => marker('REPORT'),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<PetInfoProvider> consentedOwnerWithPet() async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    await pets.giveConsent(signatureName: 'Sohail');
    await pets.addPet(bruno());
    return pets;
  }

  QuizProvider scored() {
    final quiz = QuizProvider(service: FakeCloud());
    for (final category in healthCategories) {
      for (final question in category.scoredQuestions) {
        quiz.selectAnswer(question.id, question.answers.first);
      }
    }
    quiz.calculateResult();
    return quiz;
  }

  testWidgets('the dashboard retake opens the questionnaire, not consent',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final quiz = scored();
    final pets = await consentedOwnerWithPet();

    await tester.pumpWidget(host(
      screen: const HomeDashboardScreen(),
      location: AppRoutes.home,
      quiz: quiz,
      pets: pets,
    ));
    await tester.pump();

    await tester.tap(find.text('Retake assessment'));
    await tester.pumpAndSettle();

    expect(find.text('QUIZ'), findsOneWidget);
    expect(find.text('CONSENT'), findsNothing);
  });

  testWidgets('the retake still clears the in-progress answers',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final quiz = scored();
    final pets = await consentedOwnerWithPet();
    expect(quiz.answeredCount, greaterThan(0));

    await tester.pumpWidget(host(
      screen: const HomeDashboardScreen(),
      location: AppRoutes.home,
      quiz: quiz,
      pets: pets,
    ));
    await tester.pump();
    await tester.tap(find.text('Retake assessment'));
    await tester.pumpAndSettle();

    expect(quiz.answeredCount, 0);
    // The earned score survives an abandoned retake, as before.
    expect(quiz.result, isNotNull);
  });

  testWidgets('a never-assessed dashboard starts the questionnaire directly',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pets = await consentedOwnerWithPet();

    await tester.pumpWidget(host(
      screen: const HomeDashboardScreen(),
      location: AppRoutes.home,
      quiz: QuizProvider(service: FakeCloud()),
      pets: pets,
    ));
    await tester.pump();

    await tester.tap(find.text('Start the assessment'));
    await tester.pumpAndSettle();

    expect(find.text('QUIZ'), findsOneWidget);
    expect(find.text('CONSENT'), findsNothing);
  });

  testWidgets('the empty report history starts the questionnaire too',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final pets = await consentedOwnerWithPet();

    await tester.pumpWidget(host(
      screen: const ReportHistoryScreen(),
      location: AppRoutes.reportHistory,
      quiz: QuizProvider(service: FakeCloud()),
      pets: pets,
    ));
    await tester.pump();

    await tester.tap(find.text('Start the assessment'));
    await tester.pumpAndSettle();

    expect(find.text('QUIZ'), findsOneWidget);
    expect(find.text('CONSENT'), findsNothing);
  });

  test('a set-up user lands home, never on the consent form', () {
    // Consent is reached only through the router's gate on /quiz, /pet-info
    // and /account/pets/new. No landing decision produces it.
    expect(
      AppRoutes.landingFor(hasOwner: true, hasPet: true),
      AppRoutes.home,
    );
  });
}
