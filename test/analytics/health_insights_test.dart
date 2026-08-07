import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/domain/insight_calculator.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/health_insight.dart';
import 'package:mypetfit_app/analytics/models/insight_severity.dart';
import 'package:mypetfit_app/analytics/presentation/insight_formatter.dart';
import 'package:mypetfit_app/analytics/services/analytics_engine.dart';
import 'package:mypetfit_app/analytics/widgets/insight_card.dart';
import 'package:mypetfit_app/analytics/widgets/insight_list.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 4 — health insights.
///
/// Findings are computed in the domain, worded by a formatter and rendered
/// by widgets that decide neither.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 1, 1);
  const calculator = InsightCalculator();
  const formatter = DefaultInsightFormatter();

  const skin = 'Skin & Coat Health';
  const digestive = 'Digestive & Urinary Health';
  const activity = 'Activity & Fitness Level';

  AssessmentSeries seriesOf(
    List<(int score, int dayOffset, Map<String, double> categories)> entries,
  ) =>
      AssessmentSeries(
        subjectId: 'p1',
        points: [
          for (final (score, dayOffset, categories) in entries)
            AssessmentPoint(
              id: AssessmentPoint.idFor(
                'p1',
                epoch.add(Duration(days: dayOffset)),
              ),
              takenAt: epoch.add(Duration(days: dayOffset)),
              score: score,
              band: HealthCategory.good,
              categoryScores: categories,
            ),
        ],
      );

  group('one time frame throughout', () {
    test('categories compare the last two assessments, not the whole record',
        () {
      // Skin climbs steadily: 20 over the record, 5 since last time. The
      // overall figure is also "since last time", so the two must agree
      // about what period they describe.
      final found = calculator(seriesOf([
        (50, 0, const {skin: 40}),
        (58, 30, const {skin: 55}),
        (62, 60, const {skin: 60}),
      ]));

      final overall = found.firstWhere(
        (i) => i.kind == InsightKind.overallImproved,
      );
      final category = found.firstWhere((i) => i.subject == skin);

      expect(overall.deltaPoints, 4);
      expect(category.deltaPoints, 5);
      // The whole-record figure would have been 20 — that is the category
      // cards' question, not this one's.
      expect(category.deltaPoints, isNot(20));
    });

    test('an area not measured this time has no recent change', () {
      // Reporting its older movement as recent would be the same mistake in
      // miniature.
      final found = calculator(seriesOf([
        (50, 0, const {skin: 40, digestive: 80}),
        (58, 30, const {skin: 55, digestive: 60}),
        (62, 60, const {skin: 60}),
      ]));

      expect(found.any((i) => i.subject == digestive), isFalse);
    });
  });

  group('what gets reported', () {
    test('the overall move always leads', () {
      final found = calculator(seriesOf([
        (50, 0, const {skin: 40}),
        (62, 30, const {skin: 60}),
      ]));

      expect(found.first.kind, InsightKind.overallImproved);
      expect(found.first.deltaPoints, 12);
    });

    test('a lone decline is a decline, not the biggest one', () {
      // "Declined the most" only means something when something else did.
      final found = calculator(seriesOf([
        (60, 0, const {skin: 50, activity: 70}),
        (55, 30, const {skin: 40, activity: 71}),
      ]));

      expect(
        found.map((i) => i.kind),
        contains(InsightKind.categoryDeclined),
      );
      expect(
        found.map((i) => i.kind),
        isNot(contains(InsightKind.categoryDeclinedMost)),
      );
    });

    test('with two declines, the steeper one is the superlative', () {
      final found = calculator(seriesOf([
        (60, 0, const {skin: 50, digestive: 80}),
        (50, 30, const {skin: 44, digestive: 60}),
      ]));

      final worst = found.firstWhere(
        (i) => i.kind == InsightKind.categoryDeclinedMost,
      );
      expect(worst.subject, digestive);
      expect(worst.deltaPoints, -20);
    });

    test('a move inside the noise band is not a finding', () {
      final found = calculator(seriesOf([
        (60, 0, const {skin: 50, activity: 70}),
        (70, 30, const {skin: 68, activity: 72}),
      ]));

      expect(found.any((i) => i.subject == activity), isFalse);
      expect(found.any((i) => i.subject == skin), isTrue);
    });

    test('when nothing moved, the one finding is that nothing moved', () {
      final found = calculator(seriesOf([
        (70, 0, const {skin: 50, activity: 70}),
        (71, 30, const {skin: 51, activity: 71}),
      ]));

      expect(found.single.kind, InsightKind.overallStable);
      expect(found.single.severity, InsightSeverity.neutral);
    });

    test('one assessment reports itself and invents no movement', () {
      final found = calculator(seriesOf([(70, 0, const {skin: 50})]));

      expect(found.single.kind, InsightKind.firstAssessmentRecorded);
      expect(found.single.deltaPoints, isNull);
    });

    test('an empty history produces nothing', () {
      expect(calculator(const AssessmentSeries.empty('p1')), isEmpty);
    });

    test('the same history always reads the same way', () {
      final series = seriesOf([
        (60, 0, const {'Zeta': 50, 'Alpha': 50}),
        (70, 30, const {'Zeta': 60, 'Alpha': 60}),
      ]);

      expect(calculator(series), calculator(series));
    });
  });

  group('severity belongs to the domain', () {
    test('an improvement is positive', () {
      final found = calculator(seriesOf([
        (50, 0, const {skin: 40}),
        (62, 30, const {skin: 60}),
      ]));

      expect(found.first.severity, InsightSeverity.positive);
    });

    test('a modest decline cautions, a large one alerts', () {
      final modest = calculator(seriesOf([
        (60, 0, const {skin: 50}),
        (54, 30, const {skin: 44}),
      ]));
      final large = calculator(seriesOf([
        (60, 0, const {skin: 50}),
        (40, 30, const {skin: 30}),
      ]));

      expect(modest.first.severity, InsightSeverity.caution);
      expect(large.first.severity, InsightSeverity.alert);
    });

    test('the alert threshold is configurable, not baked in', () {
      final series = seriesOf([
        (60, 0, const {skin: 50}),
        (54, 30, const {skin: 44}),
      ]);

      expect(
        const InsightCalculator(alertDecline: 5).call(series).first.severity,
        InsightSeverity.alert,
      );
    });

    test('every finding carries a severity', () {
      final found = calculator(seriesOf([
        (60, 0, const {skin: 50, digestive: 80}),
        (50, 30, const {skin: 44, digestive: 60}),
      ]));

      expect(found, isNotEmpty);
      for (final insight in found) {
        expect(
          InsightSeverity.values,
          contains(insight.severity),
          reason: '${insight.kind} shipped without a severity',
        );
      }
    });
  });

  group('the formatter', () {
    /// A finding of every kind, so coverage cannot silently lapse.
    HealthInsight sample(InsightKind kind) => HealthInsight(
          kind: kind,
          subject: kind.name.startsWith('category') ? skin : null,
          deltaPoints: kind == InsightKind.firstAssessmentRecorded ? null : -9,
        );

    test('every kind produces text', () {
      // A new kind then fails the suite rather than rendering a blank card.
      for (final kind in InsightKind.values) {
        expect(
          formatter.format(sample(kind)),
          isNotEmpty,
          reason: '$kind has no wording',
        );
      }
    });

    test('every kind produces well-formed text', () {
      for (final kind in InsightKind.values) {
        final text = formatter.format(sample(kind));

        expect(text.trim(), text, reason: '$kind has surrounding whitespace');
        expect(text.contains('  '), isFalse, reason: '$kind has a double space');
        expect(
          text.endsWith('.') || text.endsWith(',') || text.endsWith(' '),
          isFalse,
          reason: '$kind ends with punctuation; a phrase should let its '
              'caller punctuate for its own context',
        );
      }
    });

    test('a decline never reads as an improvement of a negative', () {
      final text = formatter.format(
        const HealthInsight(
          kind: InsightKind.categoryDeclined,
          subject: digestive,
          deltaPoints: -9,
        ),
      );

      expect(text, '$digestive declined by 9 points');
      expect(text.contains('-9'), isFalse);
    });

    test('the overall wording names the window it compares', () {
      expect(
        formatter.format(
          const HealthInsight(
            kind: InsightKind.overallImproved,
            deltaPoints: 12,
          ),
        ),
        'Overall health improved by 12 points since the last assessment',
      );
    });

    test('a single point is singular', () {
      expect(
        formatter.format(
          const HealthInsight(
            kind: InsightKind.categoryImproved,
            subject: skin,
            deltaPoints: 1,
          ),
        ),
        '$skin improved by 1 point',
      );
    });

    test('a portal can change the voice without touching the domain', () {
      const clinical = _ClinicalFormatter();
      const insight = HealthInsight(
        kind: InsightKind.overallDeclined,
        deltaPoints: -9,
      );

      expect(clinical.format(insight), 'Composite score down 9');
      expect(formatter.format(insight), isNot(clinical.format(insight)));
    });
  });

  group('the widgets', () {
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

    List<HealthInsight> worked() => const AnalyticsEngine()
        .analyse(seriesOf([
          (60, 0, const {skin: 50, digestive: 80}),
          (50, 30, const {skin: 44, digestive: 60}),
        ]))
        .insights;

    testWidgets('a card reads as one sentence to a screen reader',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        const InsightCard(
          insight: HealthInsight(
            kind: InsightKind.overallDeclined,
            deltaPoints: -10,
            severity: InsightSeverity.alert,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Overall health declined by 10 points since the last assessment',
        ),
        findsOneWidget,
      );
    });

    testWidgets('severity drives the treatment, not the wording',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        Column(
          children: const [
            InsightCard(
              insight: HealthInsight(
                kind: InsightKind.overallImproved,
                deltaPoints: 12,
                severity: InsightSeverity.positive,
              ),
            ),
            InsightCard(
              insight: HealthInsight(
                kind: InsightKind.overallDeclined,
                deltaPoints: -20,
                severity: InsightSeverity.alert,
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    });

    testWidgets('the list names the window it compares', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(InsightList(insights: worked())));
      await tester.pumpAndSettle();

      expect(find.text('What changed'), findsOneWidget);
      expect(
        find.text('Compared with your previous assessment.'),
        findsOneWidget,
      );
    });

    testWidgets('an empty list renders nothing at all', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(const InsightList(insights: [])));
      await tester.pumpAndSettle();

      expect(find.text('What changed'), findsNothing);
      expect(find.byType(InsightCard), findsNothing);
    });

    testWidgets('an injected formatter reaches every card', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        InsightList(insights: worked(), formatter: const _ClinicalFormatter()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Composite score'), findsOneWidget);
      expect(find.textContaining('Overall health'), findsNothing);
    });

    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 640),
        'large android': Size(412, 915),
        'tablet': Size(834, 1112),
        'landscape': Size(915, 412),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);
          // The longest sentence this can produce: a superlative kind with
          // the longest real category name.
          await tester.pumpWidget(host(
            const InsightList(
              insights: [
                HealthInsight(
                  kind: InsightKind.categoryDeclinedMost,
                  subject: 'Medical & Lifestyle Tracking',
                  deltaPoints: -37,
                  severity: InsightSeverity.alert,
                ),
                HealthInsight(
                  kind: InsightKind.overallImproved,
                  deltaPoints: 12,
                  severity: InsightSeverity.positive,
                ),
              ],
            ),
            textScale: scale,
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(InsightCard), findsNWidgets(2));
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        InsightList(insights: worked()),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Stands in for a veterinarian portal's voice.
class _ClinicalFormatter extends InsightFormatter {
  const _ClinicalFormatter();

  @override
  String format(HealthInsight insight) {
    final magnitude = (insight.deltaPoints ?? 0).abs();
    return switch (insight.kind) {
      InsightKind.overallDeclined => 'Composite score down $magnitude',
      InsightKind.overallImproved => 'Composite score up $magnitude',
      _ => 'No material change',
    };
  }
}
