import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/domain/category_sort.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/category_trend.dart';
import 'package:mypetfit_app/analytics/services/analytics_engine.dart';
import 'package:mypetfit_app/analytics/widgets/category_evolution_list.dart';
import 'package:mypetfit_app/analytics/widgets/category_trend_card.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 3 — category evolution.
///
/// The domain shipped in feature 1; this is presentation over it, plus the
/// sort mode the list carries for future surfaces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 1, 1);
  const engine = AnalyticsEngine();

  const skin = 'Skin & Coat Health';
  const digestive = 'Digestive & Urinary Health';
  const activity = 'Activity & Fitness Level';
  const medical = 'Medical & Lifestyle Tracking';

  AssessmentSeries seriesOf(
    List<(int dayOffset, Map<String, double> categories)> entries,
  ) =>
      AssessmentSeries(
        subjectId: 'p1',
        points: [
          for (final (dayOffset, categories) in entries)
            AssessmentPoint(
              id: AssessmentPoint.idFor(
                'p1',
                epoch.add(Duration(days: dayOffset)),
              ),
              takenAt: epoch.add(Duration(days: dayOffset)),
              score: 70,
              band: HealthCategory.good,
              categoryScores: categories,
            ),
        ],
      );

  /// The sprint's own worked example.
  List<CategoryTrend> worked() => engine
      .analyse(seriesOf([
        (0, const {skin: 42, digestive: 81, activity: 68}),
        (30, const {skin: 61, digestive: 74, activity: 70}),
      ]))
      .categoryTrends;

  Widget host(
    Widget child, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
      );

  void sizeAt(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('sort modes', () {
    test('the default is the worst decline first', () {
      final ordered = sortCategoryTrends(worked());

      expect(ordered.map((t) => t.name), [digestive, activity, skin]);
    });

    test('the default matches what the calculator already produced', () {
      // The calculator delegates to this comparator rather than keeping its
      // own copy of the rule, so the two cannot drift.
      expect(
        sortCategoryTrends(worked()).map((t) => t.name),
        worked().map((t) => t.name),
      );
    });

    test('improvement first inverts it', () {
      final ordered = sortCategoryTrends(
        worked(),
        mode: CategorySortMode.largestImprovementFirst,
      );

      expect(ordered.map((t) => t.name), [skin, activity, digestive]);
    });

    test('lowest current score first ignores which way it moved', () {
      // Skin climbed the most and is still the weakest — a portal asking
      // "what is worst right now" wants a different answer from "what got
      // worse".
      final ordered = sortCategoryTrends(
        worked(),
        mode: CategorySortMode.lowestCurrentScoreFirst,
      );

      expect(ordered.first.name, skin);
      expect(ordered.last.name, digestive);
    });

    test('alphabetical is alphabetical', () {
      expect(
        sortCategoryTrends(worked(), mode: CategorySortMode.alphabetical)
            .map((t) => t.name),
        [activity, digestive, skin],
      );
    });

    test('every mode breaks ties on the name', () {
      final tied = engine
          .analyse(seriesOf([
            (0, const {'Zeta': 50, 'Alpha': 50, 'Mid': 50}),
            (30, const {'Zeta': 40, 'Alpha': 40, 'Mid': 40}),
          ]))
          .categoryTrends;

      for (final mode in CategorySortMode.values) {
        expect(
          sortCategoryTrends(tied, mode: mode).map((t) => t.name),
          ['Alpha', 'Mid', 'Zeta'],
          reason: '$mode must order tied categories deterministically',
        );
      }
    });

    test('a category measured once settles at the end, not the middle', () {
      // "No news" is not a small change; ranking it as though it held steady
      // would bury a genuinely unchanged category beneath it.
      final trends = engine
          .analyse(seriesOf([
            (0, const {skin: 42, digestive: 81}),
            (30, const {skin: 61, digestive: 74, medical: 55}),
          ]))
          .categoryTrends;

      expect(sortCategoryTrends(trends).last.name, medical);
      expect(
        sortCategoryTrends(
          trends,
          mode: CategorySortMode.largestImprovementFirst,
        ).last.name,
        medical,
      );
    });

    test('sorting leaves the input alone', () {
      final trends = worked();
      final before = trends.map((t) => t.name).toList();

      sortCategoryTrends(trends, mode: CategorySortMode.alphabetical);

      expect(trends.map((t) => t.name), before);
    });
  });

  group('a card reports movement', () {
    testWidgets('an improvement shows where it started and where it is',
        (tester) async {
      sizeAt(tester, const Size(400, 900));
      final trend = worked().firstWhere((t) => t.name == skin);

      await tester.pumpWidget(host(CategoryTrendCard(trend: trend)));
      await tester.pumpAndSettle();

      expect(find.text(skin), findsOneWidget);
      expect(find.text('42 → 61'), findsOneWidget);
      expect(find.text('+19'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('a decline is reported as a decline', (tester) async {
      sizeAt(tester, const Size(400, 900));
      final trend = worked().firstWhere((t) => t.name == digestive);

      await tester.pumpWidget(host(CategoryTrendCard(trend: trend)));
      await tester.pumpAndSettle();

      expect(find.text('81 → 74'), findsOneWidget);
      expect(find.text('-7'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('a move inside the noise band claims no direction',
        (tester) async {
      sizeAt(tester, const Size(400, 900));
      // +2 is a fact; "improved" would be a claim the questionnaire cannot
      // resolve.
      final trend = worked().firstWhere((t) => t.name == activity);

      await tester.pumpWidget(host(CategoryTrendCard(trend: trend)));
      await tester.pumpAndSettle();

      expect(find.text('68 → 70'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    });

    testWidgets('a single measurement says so rather than showing nothing',
        (tester) async {
      sizeAt(tester, const Size(400, 900));
      final trends = engine
          .analyse(seriesOf([
            (0, const {skin: 42}),
            (30, const {skin: 61, medical: 55}),
          ]))
          .categoryTrends;
      final once = trends.firstWhere((t) => t.name == medical);

      await tester.pumpWidget(host(CategoryTrendCard(trend: once)));
      await tester.pumpAndSettle();

      expect(find.text('First measurement'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
      // No arrow is invented for a category with nothing to compare.
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    });

    testWidgets('a card reads as one sentence, not five numbers',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        Column(
          children: [
            for (final trend in worked()) CategoryTrendCard(trend: trend),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          '$skin, improved 19 points, from 42 to 61.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          '$digestive, declined 7 points, from 81 to 74.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('$activity, steady, from 68 to 70.'),
        findsOneWidget,
      );
    });

    testWidgets('a single measurement is spoken as unmeasured', (tester) async {
      sizeAt(tester, const Size(400, 900));
      final trends = engine
          .analyse(seriesOf([
            (0, const {skin: 42}),
            (30, const {skin: 61, medical: 55}),
          ]))
          .categoryTrends;

      await tester.pumpWidget(host(
        CategoryTrendCard(
          trend: trends.firstWhere((t) => t.name == medical),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          '$medical, first measurement, 55. Not enough history to compare.',
        ),
        findsOneWidget,
      );
    });
  });

  group('the list', () {
    testWidgets('keeps every category visible', (tester) async {
      sizeAt(tester, const Size(400, 1400));
      // Nine areas is acceptable for a health record; hiding the quiet ones
      // is how a slow decline goes unnoticed.
      final trends = engine
          .analyse(seriesOf([
            (0, {for (var i = 0; i < 9; i++) 'Area $i': 40 + i * 5},),
            (30, {for (var i = 0; i < 9; i++) 'Area $i': 45 + i * 5},),
          ]))
          .categoryTrends;

      await tester.pumpWidget(host(CategoryEvolutionList(trends: trends)));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryTrendCard), findsNWidgets(9));
    });

    testWidgets('frames itself without implying lifetime history',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(CategoryEvolutionList(trends: worked())));
      await tester.pumpAndSettle();

      expect(find.text('Category progress'), findsOneWidget);
      expect(
        find.text('First recorded to latest, across your recorded history.'),
        findsOneWidget,
      );
      // History is trimmed, so this claim would not be true.
      expect(find.textContaining('since your first'), findsNothing);
    });

    testWidgets('orders worst decline first by default', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(CategoryEvolutionList(trends: worked())));
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<CategoryTrendCard>(find.byType(CategoryTrendCard))
          .map((c) => c.trend.name)
          .toList();

      expect(names, [digestive, activity, skin]);
    });

    testWidgets('honours a sort mode without any UI selecting one',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        CategoryEvolutionList(
          trends: worked(),
          mode: CategorySortMode.largestImprovementFirst,
        ),
      ));
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<CategoryTrendCard>(find.byType(CategoryTrendCard))
          .map((c) => c.trend.name)
          .toList();

      expect(names, [skin, activity, digestive]);
    });

    testWidgets('renders nothing at all with no categories', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(const CategoryEvolutionList(trends: [])));
      await tester.pumpAndSettle();

      expect(find.text('Category progress'), findsNothing);
      expect(find.byType(CategoryTrendCard), findsNothing);
    });
  });

  group('layout', () {
    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);
          // The longest real category name, plus a longer synthetic one.
          final trends = engine
              .analyse(seriesOf([
                (0, const {
                  medical: 42,
                  'An Extremely Long Retired Health Area Name': 81,
                }),
                (30, const {
                  medical: 61,
                  'An Extremely Long Retired Health Area Name': 74,
                }),
              ]))
              .categoryTrends;

          await tester.pumpWidget(
            host(CategoryEvolutionList(trends: trends), textScale: scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(CategoryTrendCard), findsNWidgets(2));
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        CategoryEvolutionList(trends: worked()),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CategoryTrendCard), findsNWidgets(3));
    });
  });

  group('nothing is recalculated', () {
    testWidgets('stored category values render verbatim', (tester) async {
      sizeAt(tester, const Size(400, 900));
      // Deliberately not round numbers: the card must show what was stored,
      // not something derived.
      final trends = engine
          .analyse(seriesOf([
            (0, const {skin: 41.6}),
            (30, const {skin: 60.4}),
          ]))
          .categoryTrends;

      await tester.pumpWidget(host(CategoryEvolutionList(trends: trends)));
      await tester.pumpAndSettle();

      // 41.6 and 60.4 display as 42 and 60, and the delta is 18 — derived
      // from the figures actually shown rather than from the raw values, so
      // the card cannot contradict its own arithmetic. 60.4 - 41.6 would
      // round to 19 and leave a reader unable to make the numbers add up.
      expect(find.text('42 → 60'), findsOneWidget);
      expect(find.text('+18'), findsOneWidget);
    });
  });
}
