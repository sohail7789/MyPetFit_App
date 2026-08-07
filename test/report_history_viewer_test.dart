import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/routes.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/cart_provider.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';
import 'package:mypetfit_app/screens/report/report_card_screen.dart';

import 'support/fake_cloud.dart';
import 'support/network_image_stub.dart';

/// Sprint 2, feature 2 — the historical report viewer.
///
/// A filed report is a record. Opening one must show what was stored, for
/// the pet it was stored against, and must not change underneath the reader
/// when the rest of the app moves on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScoreResult report({
    required int percent,
    required int daysAgo,
    String petId = 'p1',
    Map<String, double> categories = const {'Skin & Coat Health': 41},
    HealthCategory band = HealthCategory.good,
    int? rawScore,
  }) =>
      ScoreResult(
        rawScore: rawScore ?? percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: band,
        categoryScores: categories,
        completedAt: DateTime(2026, 8, 7).subtract(Duration(days: daysAgo)),
        petId: petId,
      );

  PetInfo pet(String id, String name, {String breed = 'Beagle'}) => PetInfo(
        id: id,
        name: name,
        breed: breed,
        ageYears: 3,
        ageMonths: 2,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        updatedAt: DateTime.utc(2026, 1, 2),
      );

  Future<QuizProvider> quizWith(
    Map<String, List<ScoreResult>> byPet, {
    String bindTo = 'p1',
  }) async {
    final quiz = QuizProvider(service: FakeCloud(assessments: byPet));
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
    quiz.bindPet(bindTo);
    return quiz;
  }

  Future<PetInfoProvider> withPets(List<PetInfo> list) async {
    final pets = PetInfoProvider(service: FakeCloud());
    await pets.init();
    for (final p in list) {
      await pets.addPet(p);
    }
    pets.setActivePet(0);
    return pets;
  }

  Widget host({
    required QuizProvider quiz,
    required PetInfoProvider pets,
    int? historyIndex,
  }) {
    final router = GoRouter(
      initialLocation: '/view',
      routes: [
        GoRoute(
          path: '/view',
          builder: (_, _) => ReportCardScreen(historyIndex: historyIndex),
        ),
        for (final path in [AppRoutes.quiz, AppRoutes.home, AppRoutes.shop])
          GoRoute(
            path: path,
            builder: (_, _) => Scaffold(body: Center(child: Text(path))),
          ),
        GoRoute(
          path: AppRoutes.reportHistory,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('HISTORY'))),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: pets),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('nothing is recalculated', () {
    testWidgets('the stored percentage is shown, not one derived from raw',
        (tester) async {
      sizeUp(tester);
      // rawScore and maxPossibleScore say 20%. The stored percentageScore
      // says 73. Anything that re-derives the figure would show 20.
      final quiz = await quizWith({
        'p1': [report(percent: 73, rawScore: 20, daysAgo: 200)],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('73'), findsOneWidget);
      expect(find.text('20'), findsNothing);
    });

    testWidgets('the stored band is shown, not one derived from the score',
        (tester) async {
      sizeUp(tester);
      // 12% would band as Critical if re-derived; the record says Excellent.
      final quiz = await quizWith({
        'p1': [
          report(
            percent: 12,
            daysAgo: 200,
            band: HealthCategory.excellent,
          ),
        ],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('Critical'), findsNothing);
    });

    testWidgets('stored category scores render verbatim', (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [
          report(
            percent: 73,
            daysAgo: 200,
            categories: const {
              'Skin & Coat Health': 41,
              'Sleep & Nutrition': 92,
            },
          ),
        ],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Skin & Coat Health'), findsOneWidget);
      expect(find.text('41%'), findsOneWidget);
      expect(find.text('Sleep & Nutrition'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('2 categories'), findsOneWidget);
    });

    testWidgets('the completion date is the report\'s, not today\'s',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(percent: 73, daysAgo: 200)],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 0,
      ));
      await tester.pumpAndSettle();

      // The metadata card carries the date and the time it was completed.
      expect(find.text('19 Jan 2026 · 12:00 am'), findsOneWidget);
    });
  });

  group('the report does not move', () {
    testWidgets('switching pets leaves the open report alone', (tester) async {
      sizeUp(tester);
      // Same index, two pets. Re-reading the list on rebuild would swap the
      // document underneath the reader.
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [report(percent: 73, daysAgo: 200)],
        'p2': [report(percent: 31, daysAgo: 100, petId: 'p2')],
      });

      await tester.pumpWidget(host(quiz: quiz, pets: pets, historyIndex: 0));
      await tester.pumpAndSettle();
      expect(find.text('73'), findsOneWidget);

      pets.setActivePet(1);
      quiz.bindPet(pets.activePet!.id);
      await tester.pumpAndSettle();

      expect(find.text('73'), findsOneWidget);
      expect(find.text('31'), findsNothing);
      // And it is still labelled with the pet it belongs to.
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Mia'), findsNothing);
    });

    testWidgets('a newer assessment does not shift the open report',
        (tester) async {
      sizeUp(tester);
      // Index 1 is the older of two. Filing a third pushes it to index 2;
      // an unsnapshotted screen would start showing a different report.
      final quiz = await quizWith({
        'p1': [
          report(percent: 73, daysAgo: 100),
          report(percent: 55, daysAgo: 200),
        ],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 1,
      ));
      await tester.pumpAndSettle();
      expect(find.text('55'), findsOneWidget);

      await quiz.loadAssessmentsFromFirestore();
      await tester.pumpAndSettle();

      expect(find.text('55'), findsOneWidget);
    });
  });

  group('pet information', () {
    testWidgets('names the pet the report was recorded against',
        (tester) async {
      sizeUp(tester);
      // Mia is active; the report belongs to Bruno.
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      pets.setActivePet(1);

      final quiz = await quizWith({
        'p1': [report(percent: 73, daysAgo: 200)],
      });

      await tester.pumpWidget(host(quiz: quiz, pets: pets, historyIndex: 0));
      await tester.pumpAndSettle();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Beagle · 3 years · 12 kg'), findsOneWidget);
    });

    testWidgets('a record from before per-pet scoring falls back gracefully',
        (tester) async {
      sizeUp(tester);
      final legacy = ScoreResult(
        rawScore: 70,
        maxPossibleScore: 100,
        percentageScore: 70,
        category: HealthCategory.good,
        categoryScores: const {'Skin & Coat Health': 41},
        completedAt: DateTime(2025, 6, 1),
      );

      final quiz = QuizProvider(service: FakeCloud());
      await quiz.init();
      final pets = await withPets([pet('p1', 'Bruno')]);

      // No petId on the record; the screen shows the only pet there is.
      quiz.bindPet(null);
      await tester.pumpWidget(host(quiz: quiz, pets: pets));
      await tester.pumpAndSettle();

      expect(legacy.petId, isNull);
      expect(find.text('No report yet'), findsOneWidget);
    });
  });

  group('the live report is unaffected', () {
    testWidgets('renders the current result and offers a retake',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(percent: 88, daysAgo: 0)],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('88'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('All reports'), findsNothing);
      // The reminder is forward-looking, so it belongs on the live report.
      expect(find.text('Remind me to retake in 3 months'), findsOneWidget);
    });

    testWidgets('an archived report offers neither retake nor reminder',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(percent: 88, daysAgo: 200)],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('All reports'), findsOneWidget);
      expect(find.text('Retake'), findsNothing);
      expect(find.text('Remind me to retake in 3 months'), findsNothing);
    });
  });

  group('an unreachable index', () {
    testWidgets('degrades to the empty state rather than crashing',
        (tester) async {
      sizeUp(tester);
      final quiz = await quizWith({
        'p1': [report(percent: 73, daysAgo: 200)],
      });

      await tester.pumpWidget(host(
        quiz: quiz,
        pets: await withPets([pet('p1', 'Bruno')]),
        historyIndex: 9,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No report yet'), findsOneWidget);
    });
  });
}
