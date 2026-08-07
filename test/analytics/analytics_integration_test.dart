import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/analytics/adapters/assessment_series_adapter.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/trend_direction.dart';
import 'package:mypetfit_app/analytics/services/analytics_cache.dart';
import 'package:mypetfit_app/analytics/services/analytics_engine.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_empty_state.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_loading_state.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/providers/quiz_provider.dart';

import '../support/fake_cloud.dart';
import '../support/network_image_stub.dart';

/// Sprint 3, feature 1 — the seam and the primitives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(StubNetworkImages.install);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const adapter = AssessmentSeriesAdapter();
  final epoch = DateTime.utc(2026, 1, 1);

  ScoreResult result(
    int percent, {
    required int dayOffset,
    String petId = 'p1',
    Map<String, double> categories = const {'Skin': 40},
    HealthCategory band = HealthCategory.good,
  }) =>
      ScoreResult(
        rawScore: percent,
        maxPossibleScore: 100,
        percentageScore: percent,
        category: band,
        categoryScores: categories,
        completedAt: epoch.add(Duration(days: dayOffset)),
        petId: petId,
      );

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

  Future<QuizProvider> quizWith(Map<String, List<ScoreResult>> byPet) async {
    final quiz = QuizProvider(service: FakeCloud(assessments: byPet));
    await quiz.init();
    await quiz.loadAssessmentsFromFirestore();
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

  group('the adapter', () {
    test('turns newest-first history into a chronological series', () {
      // The one place the order flips. Getting this wrong would invert every
      // trend in the module.
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [
          result(80, dayOffset: 60),
          result(70, dayOffset: 30),
          result(60, dayOffset: 0),
        ],
      );

      expect(series.points.map((p) => p.score), [60, 70, 80]);
      expect(series.first!.score, 60);
      expect(series.latest!.score, 80);
    });

    test('copies stored values through without re-deriving them', () {
      // 12% would band as critical if derived from the score. The record
      // says excellent, and analytics must not disagree with the report.
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [
          result(12, dayOffset: 0, band: HealthCategory.excellent),
        ],
      );

      expect(series.latest!.score, 12);
      expect(series.latest!.band, HealthCategory.excellent);
    });

    test('point identities are derived, never positional', () {
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0)],
      );

      expect(series.latest!.id, AssessmentPoint.idFor('p1', epoch));
      // The same observation identifies the same way whatever else is in the
      // list — the property an index cannot offer.
      final longer = adapter.fromResults(
        subjectId: 'p1',
        results: [result(90, dayOffset: 90), result(60, dayOffset: 0)],
      );
      expect(longer.first!.id, series.latest!.id);
    });

    test('an empty history is a series, not a null', () {
      final series = adapter.fromResults(subjectId: 'p1', results: const []);

      expect(series.isEmpty, isTrue);
      expect(series.subjectId, 'p1');
    });

    test('reads the active pet from the providers', () async {
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [result(60, dayOffset: 0), result(70, dayOffset: 30)],
        'p2': [result(40, dayOffset: 10, petId: 'p2')],
      });

      final bruno = adapter.fromQuiz(quiz: quiz, pets: pets);
      expect(bruno.subjectId, 'p1');
      expect(bruno.points.map((p) => p.score), [60, 70]);

      // Switching pets swaps the whole series, with no carry-over.
      pets.setActivePet(1);
      final mia = adapter.fromQuiz(quiz: quiz, pets: pets);
      expect(mia.subjectId, 'p2');
      expect(mia.points.map((p) => p.score), [40]);
    });

    test('reads the pet by id, not the quiz binding', () async {
      // historyFor(petId) rather than the bound getters: analytics must not
      // depend on which pet the quiz happens to be pointed at.
      final pets = await withPets([pet('p1', 'Bruno'), pet('p2', 'Mia')]);
      final quiz = await quizWith({
        'p1': [result(60, dayOffset: 0)],
        'p2': [result(40, dayOffset: 10, petId: 'p2')],
      });
      quiz.bindPet('p2');

      final series = adapter.fromQuiz(quiz: quiz, pets: pets);
      expect(series.subjectId, 'p1');
      expect(series.points.single.score, 60);
    });

    test('no active pet yields an empty series rather than throwing',
        () async {
      final pets = await withPets([]);
      final quiz = await quizWith({});

      expect(adapter.fromQuiz(quiz: quiz, pets: pets).isEmpty, isTrue);
    });
  });

  group('the engine', () {
    const engine = AnalyticsEngine();

    test('an empty history claims nothing anywhere', () {
      final snapshot = engine.analyse(const AssessmentSeries.empty('p1'));

      expect(snapshot.hasHistory, isFalse);
      expect(snapshot.hasTrend, isFalse);
      expect(snapshot.categoryTrends, isEmpty);
      expect(snapshot.insights, isEmpty);
      expect(snapshot.milestones, isEmpty);
      expect(snapshot.summary.direction, TrendDirection.unknown);
    });

    test('one observation fills the summary but claims no trend', () {
      final snapshot = engine.analyse(
        adapter.fromResults(subjectId: 'p1', results: [result(70, dayOffset: 0)]),
      );

      expect(snapshot.hasHistory, isTrue);
      expect(snapshot.hasTrend, isFalse);
      expect(snapshot.summary.statistics.latestScore, 70);
      expect(snapshot.summary.direction, TrendDirection.unknown);
      expect(snapshot.milestones, isNotEmpty);
    });

    test('the same history always produces an equal snapshot', () {
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [
          result(80, dayOffset: 60, categories: const {'Skin': 60, 'Gut': 40}),
          result(70, dayOffset: 30, categories: const {'Skin': 50, 'Gut': 55}),
          result(60, dayOffset: 0, categories: const {'Skin': 40, 'Gut': 60}),
        ],
      );

      final a = engine.analyse(series);
      final b = engine.analyse(series);

      expect(a.summary, b.summary);
      expect(a.categoryTrends, b.categoryTrends);
      expect(a.insights, b.insights);
      expect(a.milestones, b.milestones);
    });

    test('holds up over a decade of history', () {
      // The module is built for far more than the five the app retains
      // today, so the engine is exercised at that scale rather than assumed.
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [
          for (var i = 0; i < 300; i++)
            result(
              40 + (i % 50),
              dayOffset: i * 12,
              categories: {'Skin': (i % 90).toDouble(), 'Gut': 50},
            ),
        ],
      );

      final watch = Stopwatch()..start();
      final snapshot = engine.analyse(series);
      watch.stop();

      expect(snapshot.assessmentCount, 300);
      expect(snapshot.categoryTrends.length, 2);
      expect(snapshot.insights, isNotEmpty);
      expect(
        watch.elapsedMilliseconds,
        lessThan(250),
        reason: 'analysing 300 observations should not approach a frame '
            'budget, let alone exceed a quarter second',
      );
    });
  });

  group('the cache', () {
    test('computes once for a given history', () {
      final cache = AnalyticsCache();
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0), result(70, dayOffset: 30)],
      );

      final first = cache.snapshotOf(series);
      expect(cache.holds(series), isTrue);
      // Identical instance, so a rebuild cannot re-derive the trend.
      expect(identical(cache.snapshotOf(series), first), isTrue);
    });

    test('recomputes when an assessment is added', () {
      final cache = AnalyticsCache();
      final before = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0)],
      );
      final after = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0), result(75, dayOffset: 30)],
      );

      final firstSnapshot = cache.snapshotOf(before);
      final secondSnapshot = cache.snapshotOf(after);

      expect(identical(firstSnapshot, secondSnapshot), isFalse);
      expect(secondSnapshot.assessmentCount, 2);
    });

    test('recomputes when the subject changes', () {
      // Two pets with identical numbers are still two different histories.
      final cache = AnalyticsCache();
      final bruno = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0)],
      );
      final mia = adapter.fromResults(
        subjectId: 'p2',
        results: [result(60, dayOffset: 0, petId: 'p2')],
      );

      cache.snapshotOf(bruno);
      expect(cache.holds(mia), isFalse);
      expect(cache.snapshotOf(mia).series.subjectId, 'p2');
    });

    test('clearing drops the held history', () {
      final cache = AnalyticsCache();
      final series = adapter.fromResults(
        subjectId: 'p1',
        results: [result(60, dayOffset: 0)],
      );

      cache.snapshotOf(series);
      cache.clear();
      expect(cache.holds(series), isFalse);
    });
  });

  group('the state primitives', () {
    Widget host(Widget child, {double textScale = 1, Brightness? brightness}) {
      return MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
      );
    }

    void sizeAt(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('the no-history state says why tracking matters',
        (tester) async {
      sizeAt(tester, const Size(400, 900));
      var started = false;

      await tester.pumpWidget(host(
        AnalyticsEmptyState.noHistory(onStart: () => started = true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Start tracking your pet’s health'), findsOneWidget);
      expect(find.bySemanticsLabel('Take the assessment'), findsOneWidget);

      await tester.tap(find.text('Take the assessment'));
      expect(started, isTrue);
    });

    testWidgets('the one-report state never promises a trend', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(
        host(const AnalyticsEmptyState.needsSecondAssessment()),
      );
      await tester.pumpAndSettle();

      expect(find.text('One assessment recorded'), findsOneWidget);
      expect(
        find.textContaining('Complete another assessment to unlock trends'),
        findsOneWidget,
      );
    });

    testWidgets('an empty state without an action shows no button',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        const AnalyticsEmptyState(
          icon: Icons.insights_outlined,
          title: 'Nothing here',
          message: 'And nothing to do about it.',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('the loading state announces itself and shows no data',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(const AnalyticsLoadingState()));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading analytics'), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale lays out',
            (tester) async {
          sizeAt(tester, entry.value);

          await tester.pumpWidget(host(
            Column(
              children: const [
                AnalyticsEmptyState.noHistory(),
                AnalyticsLoadingState(),
              ],
            ),
            textScale: scale,
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('both primitives render in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        Column(
          children: const [
            AnalyticsEmptyState.noHistory(),
            AnalyticsLoadingState(),
          ],
        ),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start tracking your pet’s health'), findsOneWidget);
    });
  });
}
