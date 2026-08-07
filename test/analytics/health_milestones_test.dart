import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/domain/milestone_calculator.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/milestone.dart';
import 'package:mypetfit_app/analytics/presentation/milestone_formatter.dart';
import 'package:mypetfit_app/analytics/widgets/milestone_card.dart';
import 'package:mypetfit_app/analytics/widgets/milestone_list.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/score_band.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 5 — health milestones.
///
/// Meaningful moments in a pet's record, computed in the domain, worded by a
/// formatter, rendered by widgets that decide neither.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 1, 1);
  const calculator = MilestoneCalculator();
  const formatter = DefaultMilestoneFormatter();

  AssessmentPoint at(int score, int dayOffset, {HealthCategory? band}) {
    final when = epoch.add(Duration(days: dayOffset));
    return AssessmentPoint(
      id: AssessmentPoint.idFor('p1', when),
      takenAt: when,
      score: score,
      // Bands normally travel with the record; derived here only so a
      // fixture does not have to state the obvious for every point.
      band: band ?? bandForPercent(score.toDouble()),
    );
  }

  AssessmentSeries series(List<AssessmentPoint> points) =>
      AssessmentSeries(subjectId: 'p1', points: points);

  DateTime day(int offset) => epoch.add(Duration(days: offset));

  /// A record that earns [kind], for the reachability test.
  AssessmentSeries earning(MilestoneKind kind) => switch (kind) {
        MilestoneKind.firstAssessment => series([at(40, 0)]),
        MilestoneKind.threeAssessments =>
          series([at(40, 0), at(41, 30), at(42, 60)]),
        MilestoneKind.tenAssessments => series([
            for (var i = 0; i < 10; i++) at(40 + i, i * 30),
          ]),
        MilestoneKind.excellentHealth => series([at(40, 0), at(90, 30)]),
        MilestoneKind.sustainedHealthy =>
          series([at(40, 0), at(80, 30), at(82, 60)]),
        MilestoneKind.recoveredToHealthy => series([at(30, 0), at(80, 30)]),
        MilestoneKind.tenPointImprovement => series([at(40, 0), at(52, 30)]),
        MilestoneKind.fiveConsecutiveImprovements => series([
            for (var i = 0; i < 6; i++) at(40 + i * 4, i * 30),
          ]),
      };

  group('every milestone is reachable', () {
    // The test that would have caught two milestones shipping unearnable.
    // The domain describes the product we want; whether today's adapter can
    // always supply enough history is the adapter's problem, not a reason
    // for a kind to exist without a path to earning it.
    for (final kind in MilestoneKind.values) {
      test('$kind can be earned', () {
        expect(
          calculator(earning(kind)).map((m) => m.kind),
          contains(kind),
          reason: '$kind has no history that earns it',
        );
      });
    }
  });

  group('when each is earned', () {
    test('the first assessment is dated at itself', () {
      final earned = calculator(series([at(40, 0)]));

      expect(earned.single.kind, MilestoneKind.firstAssessment);
      expect(earned.single.earnedAt, epoch);
    });

    test('a count milestone is dated by the observation that reached it', () {
      final earned = calculator(series([at(40, 0), at(41, 30), at(42, 60)]));

      expect(
        earned.firstWhere((m) => m.kind == MilestoneKind.threeAssessments)
            .earnedAt,
        day(60),
      );
    });

    test('excellent health is dated the first time it was reached', () {
      // A milestone records when something was achieved, not the last time
      // it happened to be true.
      final earned = calculator(series([
        at(50, 0),
        at(90, 30),
        at(92, 60),
      ]));

      expect(
        earned.firstWhere((m) => m.kind == MilestoneKind.excellentHealth)
            .earnedAt,
        day(30),
      );
    });

    test('sustained healthy needs two in a row, not two at any time', () {
      // Good, then a dip, then Good again is not sustained.
      final broken = calculator(series([at(80, 0), at(30, 30), at(80, 60)]));
      expect(
        broken.map((m) => m.kind),
        isNot(contains(MilestoneKind.sustainedHealthy)),
      );

      final held = calculator(series([at(80, 0), at(82, 30)]));
      expect(
        held.firstWhere((m) => m.kind == MilestoneKind.sustainedHealthy)
            .earnedAt,
        day(30),
      );
    });

    test('recovery is the turn itself, not merely being well later', () {
      final earned = calculator(series([
        at(30, 0),
        at(35, 30),
        at(80, 60),
        at(85, 90),
      ]));

      expect(
        earned.firstWhere((m) => m.kind == MilestoneKind.recoveredToHealthy)
            .earnedAt,
        day(60),
      );
    });

    test('a record that was never unwell has nothing to recover from', () {
      final earned = calculator(series([at(80, 0), at(85, 30)]));

      expect(
        earned.map((m) => m.kind),
        isNot(contains(MilestoneKind.recoveredToHealthy)),
      );
    });

    test('a streak is dated where the run completed, not at the newest', () {
      // Seven consecutive rises earned this two assessments ago; today's
      // date would claim the achievement is new.
      final earned = calculator(series([
        for (var i = 0; i < 8; i++) at(30 + i * 4, i * 30),
      ]));

      expect(
        earned
            .firstWhere(
              (m) => m.kind == MilestoneKind.fiveConsecutiveImprovements,
            )
            .earnedAt,
        day(150),
      );
    });

    test('a break in the run costs the streak', () {
      final earned = calculator(series([
        at(40, 0),
        at(43, 30),
        at(43, 60),
        at(46, 90),
        at(49, 120),
        at(52, 150),
      ]));

      expect(
        earned.map((m) => m.kind),
        isNot(contains(MilestoneKind.fiveConsecutiveImprovements)),
      );
    });

    test('a gain short of ten points earns nothing', () {
      final earned = calculator(series([at(50, 0), at(58, 30)]));

      expect(
        earned.map((m) => m.kind),
        isNot(contains(MilestoneKind.tenPointImprovement)),
      );
    });

    test('the thresholds are configurable, not baked in', () {
      final record = series([at(50, 0), at(56, 30)]);

      expect(
        const MilestoneCalculator(improvementPoints: 5)
            .call(record)
            .map((m) => m.kind),
        contains(MilestoneKind.tenPointImprovement),
      );
    });

    test('an empty record earns nothing', () {
      expect(calculator(const AssessmentSeries.empty('p1')), isEmpty);
    });
  });

  group('ordering', () {
    test('milestones come back chronologically, not in enum order', () {
      // The streak is late in the enum but earned last; excellent health is
      // early in the enum but reached first. Enum order would invert them.
      final earned = calculator(series([
        at(30, 0),
        at(90, 30),
        at(91, 60),
        at(92, 90),
        at(93, 120),
        at(94, 150),
      ]));

      final kinds = earned.map((m) => m.kind).toList();
      expect(kinds, contains(MilestoneKind.excellentHealth));
      expect(kinds, contains(MilestoneKind.fiveConsecutiveImprovements));
      expect(
        kinds.indexOf(MilestoneKind.excellentHealth),
        lessThan(kinds.indexOf(MilestoneKind.fiveConsecutiveImprovements)),
      );

      for (var i = 1; i < earned.length; i++) {
        expect(
          earned[i].earnedAt.isBefore(earned[i - 1].earnedAt),
          isFalse,
          reason: 'milestones must read as a history',
        );
      }
    });

    test('milestones on one observation order deterministically', () {
      final record = series([at(30, 0), at(90, 30)]);

      expect(
        calculator(record).map((m) => m.kind),
        calculator(record).map((m) => m.kind),
      );
    });
  });

  group('the healthy-band rule matches the app', () {
    test('agrees with ScoreBand.isPositive for every band', () {
      // The domain restates this because score_band.dart lives behind a
      // Flutter import; this is what stops the two drifting.
      for (final band in HealthCategory.values) {
        expect(
          isHealthyBand(band),
          band.isPositive,
          reason: '$band is classified differently by the domain and the app',
        );
      }
    });
  });

  group('the formatter', () {
    test('every kind has a title and a description', () {
      for (final kind in MilestoneKind.values) {
        expect(formatter.title(kind), isNotEmpty, reason: '$kind has no title');
        expect(
          formatter.description(kind),
          isNotEmpty,
          reason: '$kind has no description',
        );
      }
    });

    test('every group has a name', () {
      for (final group in MilestoneGroup.values) {
        expect(formatter.groupTitle(group), isNotEmpty);
      }
    });

    test('every string is well formed', () {
      for (final kind in MilestoneKind.values) {
        for (final text in [formatter.title(kind), formatter.description(kind)]) {
          expect(text.trim(), text, reason: '$kind: surrounding whitespace');
          expect(text.contains('  '), isFalse, reason: '$kind: double space');
          expect(
            text.endsWith('.') || text.endsWith(',') || text.endsWith('!'),
            isFalse,
            reason: '$kind ends with punctuation; a phrase should let its '
                'caller punctuate for its own context',
          );
        }
      }
    });

    test('every kind belongs to a group', () {
      for (final kind in MilestoneKind.values) {
        expect(MilestoneGroup.values, contains(kind.group));
      }
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

    testWidgets('a card shows when the milestone was first earned',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        MilestoneCard(
          milestone: Milestone(
            kind: MilestoneKind.recoveredToHealthy,
            earnedAt: DateTime(2026, 2, 14),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Back to healthy'), findsOneWidget);
      expect(find.text('Reached 14 Feb 2026'), findsOneWidget);
    });

    testWidgets('a card reads as one statement to a screen reader',
        (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        MilestoneCard(
          milestone: Milestone(
            kind: MilestoneKind.excellentHealth,
            earnedAt: DateTime(2026, 2, 14),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Excellent health. Reached the highest band on the assessment. '
          'Reached 14 Feb 2026',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the list renders earned milestones in the order given',
        (tester) async {
      sizeAt(tester, const Size(400, 1200));
      final earned = calculator(series([at(30, 0), at(90, 30), at(92, 60)]));

      await tester.pumpWidget(host(MilestoneList(milestones: earned)));
      await tester.pumpAndSettle();

      expect(find.text('Health milestones'), findsOneWidget);
      expect(find.byType(MilestoneCard), findsNWidgets(earned.length));

      final shown = tester
          .widgetList<MilestoneCard>(find.byType(MilestoneCard))
          .map((c) => c.milestone.kind)
          .toList();
      expect(shown, earned.map((m) => m.kind));
    });

    testWidgets('nothing unearned is teased', (tester) async {
      sizeAt(tester, const Size(400, 1200));
      // A record with one assessment earns exactly one milestone. A grid of
      // greyed-out badges would turn a health record into a progress bar.
      final earned = calculator(series([at(40, 0)]));

      await tester.pumpWidget(host(MilestoneList(milestones: earned)));
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneCard), findsOneWidget);
      expect(find.text('Ten assessments'), findsNothing);
      expect(find.text('Excellent health'), findsNothing);
    });

    testWidgets('an empty list renders nothing at all', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(const MilestoneList(milestones: [])));
      await tester.pumpAndSettle();

      expect(find.text('Health milestones'), findsNothing);
    });

    testWidgets('an injected formatter reaches every card', (tester) async {
      sizeAt(tester, const Size(400, 900));

      await tester.pumpWidget(host(
        MilestoneList(
          milestones: calculator(series([at(40, 0)])),
          formatter: const _ClinicalMilestoneFormatter(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Baseline recorded'), findsOneWidget);
      expect(find.text('First assessment'), findsNothing);
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
          final earned = [
            for (final kind in MilestoneKind.values)
              Milestone(kind: kind, earnedAt: DateTime(2026, 2, 14)),
          ];

          await tester.pumpWidget(
            host(MilestoneList(milestones: earned), textScale: scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            find.byType(MilestoneCard),
            findsNWidgets(MilestoneKind.values.length),
          );
        });
      }
    }

    testWidgets('renders in dark mode', (tester) async {
      sizeAt(tester, const Size(400, 1200));

      await tester.pumpWidget(host(
        MilestoneList(milestones: calculator(series([at(30, 0), at(90, 30)]))),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Stands in for a veterinarian portal's voice.
class _ClinicalMilestoneFormatter extends MilestoneFormatter {
  const _ClinicalMilestoneFormatter();

  @override
  String title(MilestoneKind kind) => switch (kind) {
        MilestoneKind.firstAssessment => 'Baseline recorded',
        _ => kind.name,
      };

  @override
  String description(MilestoneKind kind) => 'Recorded in the patient history';

  @override
  String groupTitle(MilestoneGroup group) => group.name;
}
