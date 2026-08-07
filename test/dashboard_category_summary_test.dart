import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/auth_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';

/// Sprint 1, feature 3 — the category summary.
///
/// Replaces "This week's focus", which cut the same data to three rows and
/// only appeared once a report existed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScoreResult report(Map<String, double> categories) => ScoreResult(
        rawScore: 70,
        maxPossibleScore: 100,
        percentageScore: 70,
        category: HealthCategory.good,
        categoryScores: categories,
        completedAt: DateTime.now(),
        petId: 'p1',
      );

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

  Future<QuizProvider> quizWith(List<ScoreResult> reports) async {
    final quiz = QuizProvider(
      service: FakeCloud(assessments: {'p1': reports}),
    );
    // The startup order: the local read first, then the cloud restore.
    // init() is what flips isLoaded, and the card watches it.
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet('p1');
    return quiz;
  }

  Future<PetInfoProvider> withBruno() async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    await pets.addPet(bruno());
    return pets;
  }

  Widget host(QuizProvider quiz, PetInfoProvider pets) {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeDashboardScreen(),
        ),
        for (final path in [
          AppRoutes.petInfo,
          AppRoutes.quiz,
          AppRoutes.report,
          AppRoutes.shop,
          AppRoutes.account,
          AppRoutes.inbox,
        ])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('ranking', () {
    test('weakest first, so the actionable rows lead', () {
      final ranked = rankedCategories(report({
        'Sleep & Nutrition': 92,
        'Skin & Coat Health': 41,
        'Activity & Fitness Level': 66,
      }));

      expect(ranked.map((e) => e.key), [
        'Skin & Coat Health',
        'Activity & Fitness Level',
        'Sleep & Nutrition',
      ]);
      // The card reads the ends of the list for its two tiles.
      expect(ranked.first.key, 'Skin & Coat Health');
      expect(ranked.last.key, 'Sleep & Nutrition');
    });

    test('ties break on name so the order cannot shuffle', () {
      final ranked = rankedCategories(report({
        'Zeta area': 50,
        'Alpha area': 50,
        'Mid area': 50,
      }));

      expect(ranked.map((e) => e.key), ['Alpha area', 'Mid area', 'Zeta area']);
    });

    test('no report ranks nothing', () {
      expect(rankedCategories(null), isEmpty);
    });

    test('a report with no breakdown ranks nothing', () {
      // Records written before categoryScores existed decode to an empty
      // map. Those fall to the preview rather than an empty card.
      expect(rankedCategories(report(const {})), isEmpty);
    });
  });

  group('the card', () {
    testWidgets('calls out the strongest and weakest areas', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([
        report({
          'Sleep & Nutrition': 92,
          'Skin & Coat Health': 41,
          'Activity & Fitness Level': 66,
        }),
      ]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.text('3 areas'), findsOneWidget);
      expect(find.text('STRONGEST'), findsOneWidget);
      expect(find.text('NEEDS WORK'), findsOneWidget);
      expect(find.text('92%'), findsWidgets);
      expect(find.text('41%'), findsWidgets);
    });

    testWidgets('lists every scored category as a bar', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([
        report({
          'Sleep & Nutrition': 92,
          'Skin & Coat Health': 41,
          'Activity & Fitness Level': 66,
        }),
      ]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      // Each name appears once in the bar list; the extremes appear again in
      // their tiles.
      expect(find.text('Activity & Fitness Level'), findsOneWidget);
      expect(find.text('Sleep & Nutrition'), findsNWidgets(2));
      expect(find.text('Skin & Coat Health'), findsNWidgets(2));
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('a single scored area shows no extreme tiles',
        (tester) async {
      sizeUp(tester);
      // Best and worst would be the same row, and two tiles saying the same
      // thing reads as a bug.
      final quiz = await quizWith([report({'Skin & Coat Health': 41})]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('1 areas'), findsOneWidget);
      expect(find.text('STRONGEST'), findsNothing);
      expect(find.text('NEEDS WORK'), findsNothing);
      expect(find.text('Skin & Coat Health'), findsOneWidget);
    });
  });

  group('empty state', () {
    testWidgets('previews what the assessment covers before any report',
        (tester) async {
      sizeUp(tester);

      final quiz = QuizProvider(service: FakeCloud());
      await quiz.init();

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('What the assessment covers'), findsOneWidget);
      expect(find.text('Category breakdown'), findsNothing);
      // The real category names, not filler.
      expect(find.text('Skin & Coat Health'), findsOneWidget);
      expect(find.text('Sleep & Nutrition'), findsOneWidget);
    });

    testWidgets('a report with no breakdown falls back to the preview',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith([report(const {})]);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pumpAndSettle();

      expect(find.text('What the assessment covers'), findsOneWidget);
    });
  });

  group('loading state', () {
    testWidgets('shows placeholder rows until the history is read',
        (tester) async {
      sizeUp(tester);
      // A provider that has not run init() yet — isLoaded is still false.
      final quiz = QuizProvider(service: FakeCloud());
      expect(quiz.isLoaded, isFalse);

      await tester.pumpWidget(host(quiz, await withBruno()));
      await tester.pump();

      expect(
        find.bySemanticsLabel('Loading category breakdown'),
        findsOneWidget,
      );
      expect(find.text('What the assessment covers'), findsNothing);

      // And it resolves once the read lands.
      await quiz.init();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading category breakdown'), findsNothing);
      expect(find.text('What the assessment covers'), findsOneWidget);
    });
  });

  group('switching pets', () {
    testWidgets('the breakdown follows the active pet', (tester) async {
      sizeUp(tester);

      final pets = PetInfoProvider(service: FakeCloud());
      await pets.init();
      await pets.addPet(bruno());
      await pets.addPet(bruno().copyWith(id: 'p2', name: 'Mia'));
      pets.setActivePet(0);

      final quiz = QuizProvider(
        service: FakeCloud(assessments: {
          'p1': [
            report({'Skin & Coat Health': 41, 'Sleep & Nutrition': 92}),
          ],
          'p2': [
            ScoreResult(
              rawScore: 40,
              maxPossibleScore: 100,
              percentageScore: 40,
              category: HealthCategory.needsImprovement,
              categoryScores: const {'Oral, Vision & Hearing': 30},
              completedAt: DateTime.now(),
              petId: 'p2',
            ),
          ],
        }),
      );
      await quiz.init();
      await quiz.loadAssessmentsFromFirestore();
      quiz.bindPet('p1');

      await tester.pumpWidget(host(quiz, pets));
      await tester.pumpAndSettle();
      expect(find.text('2 areas'), findsOneWidget);

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('1 areas'), findsOneWidget);
      expect(find.text('Oral, Vision & Hearing'), findsOneWidget);
      expect(find.text('Skin & Coat Health'), findsNothing);
    });
  });
}
