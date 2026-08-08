import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/domain/focus_calculator.dart';
import 'package:mypetfit_app/analytics/domain/overview_calculator.dart';
import 'package:mypetfit_app/analytics/domain/summary_calculator.dart';
import 'package:mypetfit_app/analytics/models/analytics_overview.dart';
import 'package:mypetfit_app/analytics/models/analytics_snapshot.dart';
import 'package:mypetfit_app/analytics/models/assessment_cadence.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/recommendation_focus.dart';
import 'package:mypetfit_app/analytics/models/trend_direction.dart';
import 'package:mypetfit_app/analytics/presentation/overview_formatter.dart';
import 'package:mypetfit_app/analytics/services/analytics_engine.dart';
import 'package:mypetfit_app/analytics/widgets/analytics_overview_card.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/score_band.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/screens/home/home_dashboard_screen.dart'
    show assessmentReminder, rankedCategories;

/// Sprint 3, feature 6 — the analytics summary dashboard.
///
/// An executive summary selected from a snapshot, worded by a formatter and
/// rendered by a card that decides neither. The tests that matter most here
/// are the invariants: a summary that could disagree with the sections
/// beneath it would be worse than no summary at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Midday, so converting to any local zone lands on a predictable date.
  final epoch = DateTime.utc(2026, 1, 1, 12);

  const engine = AnalyticsEngine();
  const calculator = OverviewCalculator();
  const formatter = DefaultOverviewFormatter();

  const skin = 'Skin & Coat';
  const digestive = 'Digestive Health';
  const dental = 'Dental Care';

  DateTime day(int offset) => epoch.add(Duration(days: offset));

  AssessmentPoint at(
    int score,
    int dayOffset, [
    Map<String, double> categories = const {},
  ]) {
    final when = day(dayOffset);
    return AssessmentPoint(
      id: AssessmentPoint.idFor('p1', when),
      takenAt: when,
      score: score,
      band: bandForPercent(score.toDouble()),
      categoryScores: categories,
    );
  }

  AnalyticsSnapshot snapshotOf(List<AssessmentPoint> points) =>
      engine.analyse(AssessmentSeries(subjectId: 'p1', points: points));

  /// A record with something in every slot: two assessments, one area up, one
  /// down, and enough history to have earned a milestone.
  AnalyticsSnapshot complete() => snapshotOf([
        at(58, 0, const {skin: 40, digestive: 70, dental: 60}),
        at(72, 90, const {skin: 62, digestive: 55, dental: 61}),
      ]);

  group('nothing is invented', () {
    test('no history produces no summary at all', () {
      final overview = calculator(snapshotOf([]), now: day(1));

      expect(overview, AnalyticsOverview.none);
      expect(overview.score, isNull);
      expect(overview.band, isNull);
      expect(overview.direction, TrendDirection.unknown);
      expect(overview.changeSincePrevious, isNull);
      expect(overview.topInsight, isNull);
      expect(overview.biggestImprovement, isNull);
      expect(overview.biggestConcern, isNull);
      expect(overview.latestMilestone, isNull);
      expect(overview.milestoneCount, 0);
      expect(overview.focus, isNull);
      expect(overview.lastAssessmentAt, isNull);
      expect(overview.nextAssessment, isNull);
      expect(overview.isEmpty, isTrue);
    });

    test('one assessment reports standing but claims no direction', () {
      final overview = calculator(
        snapshotOf([at(64, 0, const {skin: 40, digestive: 70})]),
        now: day(2),
      );

      // Known.
      expect(overview.score, 64);
      expect(overview.band, HealthCategory.good);
      expect(overview.lastAssessmentAt, day(0));
      expect(overview.nextAssessment, isNotNull);
      expect(overview.assessmentCount, 1);

      // Not known, and not guessed. "Stable" here would be a claim about a
      // comparison that was never made.
      expect(overview.direction, TrendDirection.unknown);
      expect(overview.hasTrend, isFalse);
      expect(overview.changeSincePrevious, isNull);
      expect(overview.biggestImprovement, isNull);
      expect(overview.biggestConcern, isNull);
    });

    test('one assessment still names a focus area', () {
      // The weakest area needs one reading, not two — the dashboard has
      // always recommended from a single report.
      final overview = calculator(
        snapshotOf([at(64, 0, const {skin: 40, digestive: 70})]),
        now: day(2),
      );

      expect(overview.focus?.categoryName, skin);
      expect(overview.focus?.reason, FocusReason.weakestArea);
    });

    test('a record with no category breakdown names no focus', () {
      // Assessments written before `categoryScores` existed decode to an
      // empty map. Picking a focus from nothing would be inventing one.
      final overview = calculator(snapshotOf([at(64, 0)]), now: day(2));

      expect(overview.focus, isNull);
    });

    test('two assessments unlock the trend', () {
      final overview = calculator(
        snapshotOf([at(60, 0), at(72, 90)]),
        now: day(91),
      );

      expect(overview.direction, TrendDirection.improving);
      expect(overview.changeSincePrevious, 12);
      expect(overview.hasTrend, isTrue);
    });
  });

  group('the summary agrees with the snapshot', () {
    // The invariants. Each asserts that a figure was *selected* from the
    // snapshot rather than worked out a second time — which is what makes it
    // impossible for this card to contradict the sections below it.
    test('the score and band are the snapshot’s', () {
      final snapshot = complete();
      final overview = calculator(snapshot, now: day(91));

      expect(overview.score, snapshot.summary.statistics.latestScore);
      expect(overview.band, snapshot.summary.currentBand);
      expect(overview.assessmentCount,
          snapshot.summary.statistics.assessmentCount);
      expect(overview.lastAssessmentAt,
          snapshot.summary.statistics.latestAssessmentAt);
    });

    test('the direction and change are the snapshot’s', () {
      final snapshot = complete();
      final overview = calculator(snapshot, now: day(91));

      expect(overview.direction, snapshot.summary.direction);
      expect(overview.changeSincePrevious, snapshot.summary.changeSincePrevious);
    });

    test('the top insight is the leading one the calculator ranked', () {
      final snapshot = complete();
      final overview = calculator(snapshot, now: day(91));

      expect(snapshot.insights, isNotEmpty);
      expect(overview.topInsight, snapshot.insights.first);
    });

    test('both movements are trends the snapshot holds', () {
      final snapshot = complete();
      final overview = calculator(snapshot, now: day(91));

      expect(snapshot.categoryTrends, contains(overview.biggestImprovement));
      expect(snapshot.categoryTrends, contains(overview.biggestConcern));
      expect(overview.biggestImprovement?.name, skin);
      expect(overview.biggestConcern?.name, digestive);
    });

    test('milestones come from the snapshot, newest reported', () {
      final snapshot = complete();
      final overview = calculator(snapshot, now: day(91));

      expect(snapshot.milestones, isNotEmpty);
      expect(overview.milestoneCount, snapshot.milestones.length);
      // Milestones arrive oldest first, so the most recent is the last.
      expect(overview.latestMilestone, snapshot.milestones.last);
    });

    test('the focus is the same area the dashboard would recommend for', () {
      // Parity, not similarity. Two surfaces recommending different products
      // for the same pet on the same day is the failure this prevents.
      const scores = {skin: 41.0, digestive: 55.0, dental: 78.0};
      final overview = calculator(
        snapshotOf([at(60, 0, scores), at(58, 90, scores)]),
        now: day(91),
      );

      final result = ScoreResult(
        rawScore: 58,
        maxPossibleScore: 100,
        percentageScore: 58,
        category: HealthCategory.needsImprovement,
        categoryScores: scores,
        completedAt: day(90),
      );

      expect(overview.focus?.categoryName, rankedCategories(result).first.key);
    });

    test('an empty section leaves its slot empty rather than inventing one',
        () {
      // A snapshot assembled by hand, with the sections a portal might not
      // send. Every one of them must read as absent, not as zero.
      final series = AssessmentSeries(subjectId: 'p1', points: [at(70, 0)]);
      final snapshot = AnalyticsSnapshot(
        series: series,
        summary: const SummaryCalculator()(series),
      );

      final overview = calculator(snapshot, now: day(1));

      expect(overview.topInsight, isNull);
      expect(overview.latestMilestone, isNull);
      expect(overview.milestoneCount, 0);
      expect(overview.biggestImprovement, isNull);
      expect(overview.biggestConcern, isNull);
      // What the summary did carry still comes through.
      expect(overview.score, 70);
      expect(overview.nextAssessment, isNotNull);
    });
  });

  group('movements', () {
    test('noise is not reported as a concern', () {
      // Two points of drift is inside answer-to-answer variation. Naming it
      // as the pet's biggest concern would send an owner after nothing.
      final overview = calculator(
        snapshotOf([
          at(60, 0, const {skin: 50, digestive: 50}),
          at(61, 90, const {skin: 48, digestive: 52}),
        ]),
        now: day(91),
      );

      expect(overview.biggestImprovement, isNull);
      expect(overview.biggestConcern, isNull);
    });

    test('an area measured once is neither', () {
      // "Not compared" is not "did not move".
      final overview = calculator(
        snapshotOf([
          at(60, 0, const {skin: 50}),
          at(70, 90, const {skin: 50, dental: 20}),
        ]),
        now: day(91),
      );

      expect(overview.biggestImprovement, isNull);
      expect(overview.biggestConcern, isNull);
    });

    test('a tie on improvement breaks on the name, both ways round', () {
      // Same deltas, opposite input order: the answer must not depend on
      // which category the questionnaire happened to list first.
      final forwards = calculator(
        snapshotOf([
          at(60, 0, const {digestive: 40, skin: 40}),
          at(70, 90, const {digestive: 60, skin: 60}),
        ]),
        now: day(91),
      );
      final backwards = calculator(
        snapshotOf([
          at(60, 0, const {skin: 40, digestive: 40}),
          at(70, 90, const {skin: 60, digestive: 60}),
        ]),
        now: day(91),
      );

      expect(forwards.biggestImprovement?.name, digestive);
      expect(backwards.biggestImprovement?.name, digestive);
    });

    test('a tie on concern breaks on the name, both ways round', () {
      final forwards = calculator(
        snapshotOf([
          at(70, 0, const {skin: 60, digestive: 60}),
          at(60, 90, const {skin: 40, digestive: 40}),
        ]),
        now: day(91),
      );
      final backwards = calculator(
        snapshotOf([
          at(70, 0, const {digestive: 60, skin: 60}),
          at(60, 90, const {digestive: 40, skin: 40}),
        ]),
        now: day(91),
      );

      expect(forwards.biggestConcern?.name, digestive);
      expect(backwards.biggestConcern?.name, digestive);
    });

    test('the same snapshot summarises identically twice', () {
      final snapshot = complete();

      expect(
        calculator(snapshot, now: day(91)),
        calculator(snapshot, now: day(91)),
      );
    });
  });

  group('the focus area', () {
    test('is the weakest area, not the steepest fall', () {
      // Dental falls furthest; skin is still the lowest and is what a product
      // should be recommended against.
      final overview = calculator(
        snapshotOf([
          at(60, 0, const {skin: 30, dental: 90}),
          at(58, 90, const {skin: 28, dental: 60}),
        ]),
        now: day(91),
      );

      expect(overview.focus?.categoryName, skin);
      // The steep fall is not lost — it is reported in its own right.
      expect(overview.biggestConcern?.name, dental);
    });

    test('says so when the weakest area is also falling', () {
      final overview = calculator(
        snapshotOf([
          at(60, 0, const {skin: 45, dental: 90}),
          at(58, 90, const {skin: 30, dental: 89}),
        ]),
        now: day(91),
      );

      expect(overview.focus?.categoryName, skin);
      expect(overview.focus?.reason, FocusReason.weakestAndDeclining);
    });

    test('ties break on the name', () {
      final overview = calculator(
        snapshotOf([
          at(60, 0, const {skin: 40, digestive: 40, dental: 90}),
        ]),
        now: day(1),
      );

      expect(overview.focus?.categoryName, digestive);
      expect(overview.focus?.score, 40);
    });

    test('a portal can tighten the band without forking the rule', () {
      const strict = FocusCalculator(stableBand: 0);
      final snapshot = snapshotOf([
        at(60, 0, const {skin: 45, dental: 90}),
        at(58, 90, const {skin: 44, dental: 89}),
      ]);

      // A one-point slip is noise by default and a decline to a stricter
      // consumer. Same rule, different threshold.
      expect(const FocusCalculator()(snapshot)?.reason,
          FocusReason.weakestArea);
      expect(strict(snapshot)?.reason, FocusReason.weakestAndDeclining);
    });
  });

  group('the retake cadence', () {
    const cadence = AssessmentCadence.standard;

    test('ninety days is the policy, stated once', () {
      expect(cadence.validDays, 90);
    });

    test('counts down while the assessment is current', () {
      final due = cadence.dueFrom(day(0), now: day(2))!;

      expect(due.state, AssessmentDueState.upcoming);
      expect(due.days, 88);
      expect(due.isDue, isFalse);
      expect(due.isOverdue, isFalse);
    });

    test('day 89 is still current', () {
      final due = cadence.dueFrom(day(0), now: day(89))!;

      expect(due.state, AssessmentDueState.upcoming);
      expect(due.days, 1);
      expect(due.isDue, isFalse);
    });

    test('day 90 is the day itself', () {
      final due = cadence.dueFrom(day(0), now: day(90))!;

      expect(due.state, AssessmentDueState.dueToday);
      expect(due.days, 0);
      expect(due.isDue, isTrue);
      expect(due.isOverdue, isFalse);
    });

    test('day 91 is one day overdue', () {
      final due = cadence.dueFrom(day(0), now: day(91))!;

      expect(due.state, AssessmentDueState.overdue);
      expect(due.days, 1);
      expect(due.isOverdue, isTrue);
    });

    test('a long-neglected record reports a positive number of days', () {
      final due = cadence.dueFrom(day(0), now: day(400))!;

      expect(due.state, AssessmentDueState.overdue);
      expect(due.days, 310);
      // The magnitude is never negative, whatever the state — which is why
      // "Due in -3 days" cannot be produced.
      expect(due.days, greaterThanOrEqualTo(0));
    });

    test('a future record reads as assessed today, not as extra credit', () {
      // Handsets sync records to each other and their clocks disagree.
      final due = cadence.dueFrom(day(5), now: day(0))!;

      expect(due.state, AssessmentDueState.upcoming);
      expect(due.days, 90);
    });

    test('nothing assessed is not overdue', () {
      expect(cadence.dueFrom(null, now: day(0)), isNull);
    });

    test('a tighter cadence needs no fork', () {
      const monthly = AssessmentCadence(validDays: 30);

      expect(monthly.dueFrom(day(0), now: day(31))!.isOverdue, isTrue);
      expect(cadence.dueFrom(day(0), now: day(31))!.isDue, isFalse);
    });

    test('the dashboard reminder and the overview agree on the day', () {
      // The banner used to hold its own copy of ninety days. This is the test
      // that would catch the two drifting apart again.
      for (final offset in [0, 1, 89, 90, 91, 400]) {
        final result = ScoreResult(
          rawScore: 70,
          maxPossibleScore: 100,
          percentageScore: 70,
          category: HealthCategory.good,
          completedAt: day(0),
        );

        expect(
          assessmentReminder(result, now: day(offset))?.isDue,
          cadence.dueFrom(day(0), now: day(offset))!.isDue,
          reason: 'disagreement $offset days after the assessment',
        );
      }
    });
  });

  group('the clock is a parameter', () {
    test('one snapshot, two days, two countdowns', () {
      // The reason an overview is derived at render rather than cached inside
      // an immutable snapshot.
      final snapshot = complete();

      final soon = calculator(snapshot, now: day(91));
      final later = calculator(snapshot, now: day(120));

      expect(soon.nextAssessment!.state, AssessmentDueState.upcoming);
      expect(soon.nextAssessment!.days, 89);
      expect(later.nextAssessment!.days, 60);
      expect(soon, isNot(later));

      // Everything not made of time is untouched by the clock.
      expect(soon.score, later.score);
      expect(soon.biggestConcern, later.biggestConcern);
      expect(soon.topInsight, later.topInsight);
    });

    test('an overdue record still reports the rest of the summary', () {
      final overview = calculator(complete(), now: day(400));

      expect(overview.nextAssessment!.isOverdue, isTrue);
      expect(overview.score, 72);
      expect(overview.band, isNotNull);
    });
  });

  group('the words', () {
    test('a direction nobody can claim has no wording at all', () {
      expect(formatter.trend(TrendDirection.unknown), isNull);
      expect(formatter.trend(TrendDirection.stable), 'Holding steady');
      expect(formatter.trend(TrendDirection.improving), 'Improving');
    });

    test('movement is in points, and singular reads properly', () {
      expect(formatter.change(1), 'up 1 point since your previous assessment');
      expect(
        formatter.change(-12),
        'down 12 points since your previous assessment',
      );
      expect(formatter.change(null), isNull);
    });

    test('the cadence is a prompt, never an alarm', () {
      expect(
        formatter.nextAssessment(
          AssessmentCadence.standard.dueFrom(day(0), now: day(2))!,
        ),
        'Due in 88 days',
      );
      expect(
        formatter.nextAssessment(
          AssessmentCadence.standard.dueFrom(day(0), now: day(90))!,
        ),
        'Due today',
      );
      expect(
        formatter.nextAssessment(
          AssessmentCadence.standard.dueFrom(day(0), now: day(96))!,
        ),
        'Overdue by 6 days',
      );
      expect(
        formatter.nextAssessment(
          AssessmentCadence.standard.dueFrom(day(0), now: day(91))!,
        ),
        'Overdue by 1 day',
      );
    });

    test('a due date is never phrased with a negative number', () {
      for (final offset in [0, 1, 89, 90, 91, 200, 400]) {
        final due = AssessmentCadence.standard.dueFrom(day(0), now: day(offset));
        expect(formatter.nextAssessment(due!), isNot(contains('-')));
      }
    });

    test('how long ago coarsens as it recedes', () {
      expect(formatter.lastAssessed(day(0), now: day(0)), 'Today');
      expect(formatter.lastAssessed(day(0), now: day(1)), 'Yesterday');
      expect(formatter.lastAssessed(day(0), now: day(3)), '3 days ago');
      expect(formatter.lastAssessed(day(0), now: day(20)), '2 weeks ago');
      expect(formatter.lastAssessed(day(0), now: day(400)), 'Over a year ago');
      // A record from a handset running fast reads as today, not as "in -1".
      expect(formatter.lastAssessed(day(5), now: day(0)), 'Today');
    });

    test('the recorded window is named honestly', () {
      final overview = calculator(complete(), now: day(91));

      expect(
        formatter.movement(overview.biggestImprovement!),
        'Up 22 points across your recorded history',
      );
    });

    test('milestones summarise without listing', () {
      final overview = calculator(complete(), now: day(91));

      expect(
        formatter.milestones(overview.latestMilestone!, overview.milestoneCount),
        contains('and'),
      );
      expect(
        formatter.milestones(overview.latestMilestone!, 1),
        isNot(contains('and')),
      );
    });

    test('a portal can change the voice without touching the domain', () {
      const clinical = _ClinicalOverviewFormatter();

      expect(clinical.concernLabel, 'Presenting concern');
      expect(clinical.concernLabel, isNot(formatter.concernLabel));
    });

    test('the spoken summary is a passage, not a pile of labels', () {
      final spoken = formatter.spoken(
        calculator(complete(), now: day(91)),
        now: day(91),
      );

      expect(spoken, startsWith('Health overview.'));
      expect(spoken, contains('Overall health score 72, Good'));
      expect(spoken, contains('Improving'));
      expect(spoken, contains('Biggest concern: $digestive'));
      expect(spoken, contains('Next assessment due in 89 days'));
    });

    test('what is unknown is not spoken', () {
      final spoken = formatter.spoken(
        calculator(snapshotOf([at(64, 0)]), now: day(2)),
        now: day(2),
      );

      expect(spoken, contains('Overall health score 64'));
      expect(spoken, isNot(contains('Improving')));
      expect(spoken, isNot(contains('Holding steady')));
      expect(spoken, isNot(contains('Biggest')));
    });
  });

  group('the card', () {
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

    testWidgets('a full record shows every slot', (tester) async {
      sizeAt(tester, const Size(400, 1400));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: calculator(complete(), now: day(91)),
        now: day(91),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Health overview'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Top insight'), findsOneWidget);
      expect(find.text('Biggest improvement'), findsOneWidget);
      expect(find.text('Biggest concern'), findsOneWidget);
      expect(find.text('Health milestones'), findsOneWidget);
      expect(find.text('Focus area'), findsOneWidget);
      expect(find.text('Last assessed'), findsOneWidget);
      expect(find.text('Next assessment'), findsOneWidget);
      expect(find.text('Due in 89 days'), findsOneWidget);
    });

    testWidgets('one assessment leaves the unknown rows out entirely',
        (tester) async {
      sizeAt(tester, const Size(400, 1400));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: calculator(
          snapshotOf([at(64, 0, const {skin: 40, digestive: 70})]),
          now: day(2),
        ),
        now: day(2),
      )));
      await tester.pumpAndSettle();

      // Present.
      expect(find.text('64'), findsOneWidget);
      expect(find.text('Last assessed'), findsOneWidget);
      expect(find.text('Focus area'), findsOneWidget);

      // Absent — and absent means gone, not blank. No placeholder dash, and
      // above all no "Holding steady" standing in for a comparison that was
      // never made.
      expect(find.text('Biggest improvement'), findsNothing);
      expect(find.text('Biggest concern'), findsNothing);
      expect(find.text('Holding steady'), findsNothing);
      expect(find.text('Improving'), findsNothing);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('nothing recorded renders nothing at all', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: AnalyticsOverview.none,
        now: day(0),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Health overview'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the summary reads as one passage to a screen reader',
        (tester) async {
      sizeAt(tester, const Size(400, 1400));

      final overview = calculator(complete(), now: day(91));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: overview,
        now: day(91),
      )));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(formatter.spoken(overview, now: day(91))),
        findsOneWidget,
      );
    });

    testWidgets('the recommendation slot stays outside the summary',
        (tester) async {
      sizeAt(tester, const Size(400, 1400));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: calculator(complete(), now: day(91)),
        now: day(91),
        recommendation: const Text('A product someone merchandised'),
      )));
      await tester.pumpAndSettle();

      // Rendered, and not swallowed by the passage above it.
      expect(find.text('A product someone merchandised'), findsOneWidget);
    });

    testWidgets('an injected formatter reaches the whole card', (tester) async {
      sizeAt(tester, const Size(400, 1400));

      await tester.pumpWidget(host(AnalyticsOverviewCard(
        overview: calculator(complete(), now: day(91)),
        now: day(91),
        formatter: const _ClinicalOverviewFormatter(),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Presenting concern'), findsOneWidget);
      expect(find.text('Biggest concern'), findsNothing);
    });

    for (final scale in [1.0, 1.3]) {
      for (final entry in const {
        'small android': Size(320, 1600),
        'large android': Size(412, 1600),
        'tablet': Size(834, 1600),
        'landscape': Size(915, 600),
      }.entries) {
        testWidgets('${entry.key} at text scale $scale', (tester) async {
          sizeAt(tester, entry.value);

          // The longest content this can produce: real category names, a
          // superlative insight and an overdue cadence.
          await tester.pumpWidget(host(
            AnalyticsOverviewCard(
              overview: calculator(
                snapshotOf([
                  at(58, 0, const {
                    'Medical & Lifestyle Tracking': 40,
                    'Behavior & Mental Wellness': 70,
                  }),
                  at(72, 90, const {
                    'Medical & Lifestyle Tracking': 62,
                    'Behavior & Mental Wellness': 51,
                  }),
                ]),
                now: day(400),
              ),
              now: day(400),
            ),
            textScale: scale,
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Health overview'), findsOneWidget);
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 1400));

      await tester.pumpWidget(host(
        AnalyticsOverviewCard(
          overview: calculator(complete(), now: day(91)),
          now: day(91),
        ),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Stands in for a veterinarian portal's voice.
///
/// Extends the default rather than the abstract base, which is the whole
/// point of the split: changing one heading should not mean restating twenty.
class _ClinicalOverviewFormatter extends DefaultOverviewFormatter {
  const _ClinicalOverviewFormatter();

  @override
  String get concernLabel => 'Presenting concern';
}
