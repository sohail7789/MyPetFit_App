import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/trend_extremes.dart';
import 'package:mypetfit_app/analytics/services/analytics_engine.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_theme.dart';
import 'package:mypetfit_app/analytics/widgets/trend_graph.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 2 — the graph as a widget.
///
/// Presentation only: it must plot what is stored, never re-derive it, and
/// stay reachable by touch and by screen reader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 1, 1);
  const engine = AnalyticsEngine();

  AssessmentSeries seriesOf(
    List<(int score, int dayOffset)> entries, {
    String subjectId = 'p1',
    HealthCategory? band,
  }) =>
      AssessmentSeries(
        subjectId: subjectId,
        points: [
          for (final (score, dayOffset) in entries)
            AssessmentPoint(
              id: AssessmentPoint.idFor(
                subjectId,
                epoch.add(Duration(days: dayOffset)),
              ),
              takenAt: epoch.add(Duration(days: dayOffset)),
              score: score,
              band: band ?? HealthCategory.good,
            ),
        ],
      );

  Widget host(
    Widget child, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool reduceMotion = false,
  }) =>
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: inner!,
        ),
      );

  void sizeAt(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('what gets a marker', () {
    testWidgets('the latest, the highest and the lowest', (tester) async {
      sizeAt(tester, const Size(400, 800));
      // Peak in the middle, trough second, latest at the end — three
      // distinct observations, so three markers.
      final snapshot = engine.analyse(
        seriesOf([(60, 0), (95, 30), (35, 60), (70, 90)]),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('^Highest,')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Lowest,')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Latest,')), findsOneWidget);
    });

    testWidgets('hundreds of observations still draw only a few markers',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // The scalability requirement: the line covers every observation, the
      // widget count does not grow with the history.
      final snapshot = engine.analyse(
        seriesOf([for (var i = 0; i < 300; i++) (40 + (i % 50), i * 12)]),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      expect(snapshot.assessmentCount, 300);
      expect(
        find.bySemanticsLabel(RegExp(r'percent, ')).evaluate().length,
        lessThanOrEqualTo(4),
        reason: 'only the notable observations should be widgets — the marker '
            'count must not grow with the history',
      );
    });

    testWidgets('one observation is announced once, not three times',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // A single point is its own best, worst and latest. Three markers on
      // one dot, or three roles read out for it, would look broken.
      final snapshot = engine.analyse(seriesOf([(70, 0)]));

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('^Latest,')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Highest,')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Lowest,')), findsNothing);
    });

    testWidgets('equal highs mark the earliest, and it is not also the latest',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // Two observations at the same score: the first is the peak (earliest
      // on a tie) and the second is the current standing.
      final snapshot = engine.analyse(seriesOf([(70, 0), (70, 30)]));

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('^Highest, 1 Jan 2026')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Latest, 31 Jan 2026')), findsOneWidget);
    });
  });

  group('opening a report', () {
    testWidgets('a marker reports the stable id of its own observation',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      final series = seriesOf([(60, 0), (95, 30), (35, 60), (70, 90)]);
      final snapshot = engine.analyse(series);
      String? opened;

      await tester.pumpWidget(host(
        TrendGraph(snapshot: snapshot, onOpenReport: (id) => opened = id),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(RegExp('^Highest,')));
      await tester.pumpAndSettle();

      // The 95 was the second observation.
      expect(opened, series.points[1].id);
      // Never a list position.
      expect(opened, isNot('1'));
    });

    testWidgets('the latest marker opens the latest report', (tester) async {
      sizeAt(tester, const Size(400, 800));
      final series = seriesOf([(60, 0), (95, 30), (70, 90)]);
      String? opened;

      await tester.pumpWidget(host(
        TrendGraph(
          snapshot: engine.analyse(series),
          onOpenReport: (id) => opened = id,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(RegExp('^Latest,')));
      await tester.pumpAndSettle();

      expect(opened, series.points.last.id);
    });

    testWidgets('a marker is a full touch target however small the dot looks',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      final snapshot = engine.analyse(seriesOf([(60, 0), (95, 30), (70, 90)]));

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.bySemanticsLabel(RegExp('^Latest,')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('selecting a point without a marker', () {
    testWidgets('tapping the chart selects the nearest observation',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // The middle observation is neither best, worst nor latest, so it has
      // no marker — it must still be reachable.
      final snapshot = engine.analyse(
        seriesOf([(30, 0), (68, 30), (72, 60), (95, 90)]),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      final chart = tester.getRect(find.byType(TrendGraph));
      // A third of the way across lands nearest the second observation.
      await tester.tapAt(
        Offset(chart.left + chart.width * 0.34, chart.center.dy),
      );
      await tester.pumpAndSettle();

      // The callout reports the selection's own stored values.
      expect(find.text('68%'), findsOneWidget);
    });

    testWidgets('the callout names the date and the band', (tester) async {
      sizeAt(tester, const Size(400, 800));
      final snapshot = engine.analyse(
        seriesOf([(30, 0), (68, 30), (72, 60), (95, 90)]),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      final chart = tester.getRect(find.byType(TrendGraph));
      await tester.tapAt(
        Offset(chart.left + chart.width * 0.34, chart.center.dy),
      );
      await tester.pumpAndSettle();

      expect(find.text('31 Jan 2026'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });
  });

  group('nothing is recalculated', () {
    testWidgets('a stored band that disagrees with its score is honoured',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // 12 would band as Critical if re-derived. The record says Excellent,
      // and analytics must not contradict the report it came from.
      final series = AssessmentSeries(
        subjectId: 'p1',
        points: [
          AssessmentPoint(
            id: 'a',
            takenAt: epoch,
            score: 70,
            band: HealthCategory.good,
          ),
          AssessmentPoint(
            id: 'b',
            takenAt: epoch.add(const Duration(days: 30)),
            score: 12,
            band: HealthCategory.excellent,
          ),
        ],
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: engine.analyse(series))));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Latest,.*12 percent, Excellent')),
        findsOneWidget,
      );
    });
  });

  group('accessibility', () {
    testWidgets('the chart summarises itself rather than dumping the data',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      // The per-assessment enumeration is the list this graph sits above;
      // repeating it here would double the screen's length to hear.
      final snapshot = engine.analyse(
        seriesOf([(60, 0), (95, 30), (35, 60), (70, 90)]),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Health trend chart, 4 assessments. Latest 70 percent, Good. '
          'Highest 95, lowest 35.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reduce motion skips the draw-in entirely', (tester) async {
      sizeAt(tester, const Size(400, 800));
      final snapshot = engine.analyse(seriesOf([(60, 0), (95, 30), (70, 90)]));

      await tester.pumpWidget(
        host(TrendGraph(snapshot: snapshot), reduceMotion: true),
      );
      // A single frame: with animation the line would still be growing.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel(RegExp('^Latest,')), findsOneWidget);
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
          final snapshot = engine.analyse(
            seriesOf([(60, 0), (95, 30), (35, 60), (70, 90)]),
          );

          await tester.pumpWidget(
            host(TrendGraph(snapshot: snapshot), textScale: scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(TrendGraph), findsOneWidget);
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 800));
      final snapshot = engine.analyse(seriesOf([(60, 0), (95, 30), (70, 90)]));

      await tester.pumpWidget(
        host(TrendGraph(snapshot: snapshot), brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a callout for the newest point stays on the chart',
        (tester) async {
      sizeAt(tester, const Size(320, 640));
      final snapshot = engine.analyse(seriesOf([(60, 0), (70, 30), (95, 60)]));

      await tester.pumpWidget(host(TrendGraph(snapshot: snapshot)));
      await tester.pumpAndSettle();

      final chart = tester.getRect(find.byType(TrendGraph));
      await tester.tapAt(Offset(chart.right - 4, chart.center.dy));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final callout = tester.getRect(find.text('95%'));
      expect(callout.right, lessThanOrEqualTo(chart.right + 0.5));
    });
  });

  group('the theme carries the judgements', () {
    testWidgets('a scoped theme reaches the graph', (tester) async {
      sizeAt(tester, const Size(400, 800));
      final snapshot = engine.analyse(seriesOf([(60, 0), (95, 30), (70, 90)]));

      await tester.pumpWidget(host(
        AnalyticsThemeScope(
          theme: const AnalyticsTheme(chartHeight: 240, minimumScoreSpan: 10),
          child: TrendGraph(snapshot: snapshot),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(TrendGraph)).height, 240);
    });

    test('the default span is conservative', () {
      // The judgement itself, pinned: a tightly fitted axis makes a small
      // change look like a crisis.
      expect(const AnalyticsTheme().minimumScoreSpan, greaterThanOrEqualTo(30));
      expect(const AnalyticsTheme().minimumTapTarget, greaterThanOrEqualTo(48));
    });
  });

  group('switching pets', () {
    testWidgets('a selection does not survive onto another pet',
        (tester) async {
      sizeAt(tester, const Size(400, 800));
      final bruno = engine.analyse(
        seriesOf([(30, 0), (68, 30), (72, 60), (95, 90)]),
      );
      final mia = engine.analyse(
        seriesOf([(40, 0), (44, 30), (48, 60), (52, 90)], subjectId: 'p2'),
      );

      await tester.pumpWidget(host(TrendGraph(snapshot: bruno)));
      await tester.pumpAndSettle();

      final chart = tester.getRect(find.byType(TrendGraph));
      await tester.tapAt(
        Offset(chart.left + chart.width * 0.34, chart.center.dy),
      );
      await tester.pumpAndSettle();
      expect(find.text('68%'), findsOneWidget);

      await tester.pumpWidget(host(TrendGraph(snapshot: mia)));
      await tester.pumpAndSettle();

      expect(find.text('68%'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('Latest,.*52 percent')),
        findsOneWidget,
      );
    });
  });

  group('the extremes value', () {
    test('a single observation is its own best, worst and latest', () {
      final extremes = TrendExtremes.of(seriesOf([(70, 0)]))!;

      expect(extremes.best.id, extremes.worst.id);
      expect(extremes.areDistinct, isFalse);
      expect(extremes.marks(extremes.latest.id), isTrue);
    });

    test('ties resolve to the earliest, matching how milestones are dated',
        () {
      final extremes = TrendExtremes.of(
        seriesOf([(90, 0), (90, 30), (50, 60)]),
      )!;

      expect(extremes.best.takenAt, epoch);
    });

    test('an empty history has no extremes', () {
      expect(TrendExtremes.of(const AssessmentSeries.empty('p1')), isNull);
    });

    test('the statistics and the extremes cannot disagree', () {
      // Two views of the same facts for two consumers; a test rather than a
      // shared field, so neither has to carry the other's shape.
      final snapshot = engine.analyse(seriesOf([(60, 0), (95, 30), (35, 60)]));

      expect(snapshot.summary.statistics.bestScore, snapshot.extremes!.best.score);
      expect(
        snapshot.summary.statistics.worstScore,
        snapshot.extremes!.worst.score,
      );
      expect(
        snapshot.summary.statistics.latestScore,
        snapshot.extremes!.latest.score,
      );
    });
  });
}
