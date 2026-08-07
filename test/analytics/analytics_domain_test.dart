import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/analytics/domain/achievement_calculator.dart';
import 'package:mypetfit_app/analytics/domain/category_trend_calculator.dart';
import 'package:mypetfit_app/analytics/domain/insight_calculator.dart';
import 'package:mypetfit_app/analytics/domain/statistics_calculator.dart';
import 'package:mypetfit_app/analytics/domain/summary_calculator.dart';
import 'package:mypetfit_app/analytics/domain/trend_calculator.dart';
import 'package:mypetfit_app/analytics/models/achievement.dart';
import 'package:mypetfit_app/analytics/models/assessment_point.dart';
import 'package:mypetfit_app/analytics/models/assessment_series.dart';
import 'package:mypetfit_app/analytics/models/health_insight.dart';
import 'package:mypetfit_app/analytics/models/trend_direction.dart';
import 'package:mypetfit_app/models/score_result.dart';

/// Sprint 3, feature 1 — the deterministic layer.
///
/// Pure functions over stored history, so none of this needs a widget tree,
/// a provider or a clock.
void main() {
  final epoch = DateTime.utc(2026, 1, 1);

  AssessmentPoint point(
    int score, {
    required int dayOffset,
    HealthCategory? band,
    Map<String, double> categories = const {},
  }) {
    final at = epoch.add(Duration(days: dayOffset));
    return AssessmentPoint(
      id: AssessmentPoint.idFor('p1', at),
      takenAt: at,
      score: score,
      band: band ?? HealthCategory.good,
      categoryScores: categories,
    );
  }

  /// Oldest first, as the series contract requires.
  AssessmentSeries series(List<AssessmentPoint> points) =>
      AssessmentSeries(subjectId: 'p1', points: points);

  group('series contract', () {
    test('a single observation is not a trend', () {
      expect(series([point(70, dayOffset: 0)]).hasTrend, isFalse);
      expect(
        series([point(70, dayOffset: 0), point(72, dayOffset: 30)]).hasTrend,
        isTrue,
      );
    });

    test('identity changes when the history does, and not otherwise', () {
      final one = series([point(70, dayOffset: 0)]);
      final same = series([point(70, dayOffset: 0)]);
      final added = series([point(70, dayOffset: 0), point(75, dayOffset: 30)]);

      expect(one.identity, same.identity);
      expect(one.identity, isNot(added.identity));
      // A different subject with identical numbers is a different history.
      expect(
        AssessmentSeries(subjectId: 'p2', points: one.points).identity,
        isNot(one.identity),
      );
    });

    test('category names union across the history, in first-seen order', () {
      // A category added later, and one dropped later, both belong to the
      // record — losing either would rewrite the past.
      final s = series([
        point(70, dayOffset: 0, categories: const {'Skin': 40, 'Sleep': 80}),
        point(75, dayOffset: 30, categories: const {'Skin': 55, 'Activity': 60}),
      ]);

      expect(s.categoryNames, ['Skin', 'Sleep', 'Activity']);
    });
  });

  group('statistics', () {
    const calculator = StatisticsCalculator();

    test('nothing recorded yields nothing claimed', () {
      final stats = calculator(const AssessmentSeries.empty('p1'));

      expect(stats.assessmentCount, 0);
      expect(stats.bestScore, isNull);
      expect(stats.averageScore, isNull);
      expect(stats.hasHistory, isFalse);
    });

    test('best, worst, latest and average over the whole history', () {
      final stats = calculator(series([
        point(60, dayOffset: 0),
        point(90, dayOffset: 30),
        point(72, dayOffset: 60),
      ]));

      expect(stats.assessmentCount, 3);
      expect(stats.bestScore, 90);
      expect(stats.worstScore, 60);
      // Latest is the newest observation, not the highest.
      expect(stats.latestScore, 72);
      expect(stats.averageScore, closeTo(74, 0.001));
    });

    test('the average keeps its precision for the UI to round', () {
      final stats = calculator(series([
        point(74, dayOffset: 0),
        point(75, dayOffset: 30),
      ]));

      expect(stats.averageScore, 74.5);
    });

    test('the tracking span covers first to latest', () {
      final stats = calculator(series([
        point(60, dayOffset: 0),
        point(70, dayOffset: 400),
      ]));

      expect(stats.trackingSpanDays, 400);
    });

    test('a single observation spans no days', () {
      expect(calculator(series([point(60, dayOffset: 0)])).trackingSpanDays, 0);
    });
  });

  group('trend', () {
    const calculator = TrendCalculator();

    test('no direction is claimed from one observation', () {
      final s = series([point(70, dayOffset: 0)]);

      // "We cannot say" is a different claim from "it has not changed".
      expect(calculator.direction(s), TrendDirection.unknown);
      expect(calculator.changeSincePrevious(s), isNull);
      expect(calculator.changeSinceFirst(s), isNull);
    });

    test('direction reads the latest move, not the whole history', () {
      // Climbed for a year, then fell sharply — that pet is not improving.
      final s = series([
        point(50, dayOffset: 0),
        point(80, dayOffset: 180),
        point(62, dayOffset: 360),
      ]);

      expect(calculator.direction(s), TrendDirection.declining);
      expect(calculator.changeSincePrevious(s), -18);
      // The whole-history view is still available, and disagrees.
      expect(calculator.changeSinceFirst(s), 12);
    });

    test('movement inside the noise band reads as stable', () {
      for (final delta in [-2, -1, 0, 1, 2]) {
        final s = series([
          point(70, dayOffset: 0),
          point(70 + delta, dayOffset: 30),
        ]);
        expect(
          calculator.direction(s),
          TrendDirection.stable,
          reason: 'a move of $delta should be stable',
        );
      }
    });

    test('movement past the band reads as direction', () {
      final up = series([point(70, dayOffset: 0), point(73, dayOffset: 30)]);
      final down = series([point(70, dayOffset: 0), point(67, dayOffset: 30)]);

      expect(calculator.direction(up), TrendDirection.improving);
      expect(calculator.direction(down), TrendDirection.declining);
    });

    test('a clinical consumer can tighten the band without a fork', () {
      final s = series([point(70, dayOffset: 0), point(72, dayOffset: 30)]);

      expect(const TrendCalculator().direction(s), TrendDirection.stable);
      expect(
        const TrendCalculator(stableBand: 0).direction(s),
        TrendDirection.improving,
      );
    });

    test('a streak counts consecutive rises back from the latest', () {
      final s = series([
        point(40, dayOffset: 0),
        point(50, dayOffset: 30),
        point(60, dayOffset: 60),
        point(70, dayOffset: 90),
      ]);

      expect(calculator.improvementStreak(s), 3);
    });

    test('a flat result breaks a streak', () {
      // A streak claims consecutive progress; standing still is not progress.
      final s = series([
        point(40, dayOffset: 0),
        point(50, dayOffset: 30),
        point(50, dayOffset: 60),
        point(60, dayOffset: 90),
      ]);

      expect(calculator.improvementStreak(s), 1);
    });
  });

  group('summary', () {
    const calculator = SummaryCalculator();

    test('an empty history claims nothing', () {
      final summary = calculator(const AssessmentSeries.empty('p1'));

      expect(summary.hasHistory, isFalse);
      expect(summary.direction, TrendDirection.unknown);
      expect(summary.currentBand, isNull);
    });

    test('carries the stored band, not one derived from the score', () {
      // 12 would band as critical if re-derived. The record says excellent,
      // and a historical record reads the way it was filed.
      final summary = calculator(series([
        point(70, dayOffset: 0),
        point(12, dayOffset: 30, band: HealthCategory.excellent),
      ]));

      expect(summary.currentBand, HealthCategory.excellent);
      expect(summary.statistics.latestScore, 12);
    });
  });

  group('category trends', () {
    const calculator = CategoryTrendCalculator();

    test('largest decline leads, so attention goes to the right place', () {
      final trends = calculator(series([
        point(70, dayOffset: 0, categories: const {
          'Skin': 42,
          'Digestive': 81,
          'Activity': 68,
        }),
        point(72, dayOffset: 30, categories: const {
          'Skin': 61,
          'Digestive': 74,
          'Activity': 70,
        }),
      ]));

      expect(trends.map((t) => t.name), ['Digestive', 'Activity', 'Skin']);
      expect(trends.first.delta, -7);
      expect(trends.last.delta, 19);
    });

    test('a category measured once carries no movement and sorts last', () {
      final trends = calculator(series([
        point(70, dayOffset: 0, categories: const {'Skin': 42}),
        point(72, dayOffset: 30, categories: const {
          'Skin': 61,
          'Activity': 60,
        }),
      ]));

      expect(trends.map((t) => t.name), ['Skin', 'Activity']);
      expect(trends.last.delta, isNull);
      expect(trends.last.direction(), TrendDirection.unknown);
    });

    test('an unmeasured category leaves no point rather than a zero', () {
      // "Not measured" is not "measured as nought" — a gap must not read as
      // a catastrophic decline.
      final trends = calculator(series([
        point(70, dayOffset: 0, categories: const {'Skin': 42}),
        point(72, dayOffset: 30, categories: const {'Activity': 60}),
        point(74, dayOffset: 60, categories: const {'Skin': 50}),
      ]));

      final skin = trends.firstWhere((t) => t.name == 'Skin');
      expect(skin.points.length, 2);
      expect(skin.first, 42);
      expect(skin.latest, 50);
      expect(skin.delta, 8);
    });

    test('ties break on name so the order cannot shuffle', () {
      final s = series([
        point(70, dayOffset: 0, categories: const {'Zeta': 50, 'Alpha': 50}),
        point(72, dayOffset: 30, categories: const {'Zeta': 40, 'Alpha': 40}),
      ]);

      expect(calculator(s).map((t) => t.name), ['Alpha', 'Zeta']);
      expect(calculator(s).map((t) => t.name), ['Alpha', 'Zeta']);
    });

    test('every point carries the observation it came from', () {
      // A tapped category point has to be able to open its own report.
      final trends = calculator(series([
        point(70, dayOffset: 0, categories: const {'Skin': 42}),
        point(72, dayOffset: 30, categories: const {'Skin': 61}),
      ]));

      expect(
        trends.single.points.map((p) => p.pointId),
        [
          AssessmentPoint.idFor('p1', epoch),
          AssessmentPoint.idFor('p1', epoch.add(const Duration(days: 30))),
        ],
      );
    });
  });

  group('insights', () {
    const calculator = InsightCalculator();

    test('an empty history produces nothing', () {
      expect(calculator(const AssessmentSeries.empty('p1')), isEmpty);
    });

    test('one observation reports itself, and invents no movement', () {
      final found = calculator(series([point(70, dayOffset: 0)]));

      expect(found.single.kind, InsightKind.firstAssessmentRecorded);
      expect(found.single.deltaPoints, isNull);
    });

    test('the overall move leads, and carries its size', () {
      final found = calculator(series([
        point(60, dayOffset: 0, categories: const {'Skin': 40}),
        point(72, dayOffset: 30, categories: const {'Skin': 58}),
      ]));

      expect(found.first.kind, InsightKind.overallImproved);
      expect(found.first.deltaPoints, 12);
    });

    test('a decline is reported as a decline', () {
      final found = calculator(series([
        point(72, dayOffset: 0),
        point(60, dayOffset: 30),
      ]));

      expect(found.first.kind, InsightKind.overallDeclined);
      expect(found.first.deltaPoints, -12);
    });

    test('a move inside the noise band reports as stable', () {
      final found = calculator(series([
        point(70, dayOffset: 0),
        point(71, dayOffset: 30),
      ]));

      expect(found.first.kind, InsightKind.overallStable);
      expect(found.first.deltaPoints, 1);
    });

    test('names the biggest faller and the biggest riser', () {
      final found = calculator(series([
        point(70, dayOffset: 0, categories: const {
          'Skin': 42,
          'Digestive': 81,
          'Activity': 68,
        }),
        point(72, dayOffset: 30, categories: const {
          'Skin': 61,
          'Digestive': 72,
          'Activity': 69,
        }),
      ]));

      final byKind = {for (final i in found) i.kind: i};
      expect(byKind[InsightKind.categoryDeclinedMost]?.subject, 'Digestive');
      expect(byKind[InsightKind.categoryDeclinedMost]?.deltaPoints, -9);
      expect(byKind[InsightKind.categoryImprovedMost]?.subject, 'Skin');
      expect(byKind[InsightKind.categoryImprovedMost]?.deltaPoints, 19);
      // Activity moved by one — inside the noise band, so it is not a finding.
      expect(found.any((i) => i.subject == 'Activity'), isFalse);
    });

    test('a single moving category is not both the best and the worst', () {
      final found = calculator(series([
        point(70, dayOffset: 0, categories: const {'Skin': 42}),
        point(72, dayOffset: 30, categories: const {'Skin': 61}),
      ]));

      final skin = found.where((i) => i.subject == 'Skin');
      expect(skin.length, 1);
    });

    test('the list is capped and ordered by how much moved', () {
      final found = InsightCalculator(limit: 2)(series([
        point(70, dayOffset: 0, categories: const {
          'A': 10,
          'B': 90,
          'C': 50,
          'D': 50,
        }),
        point(90, dayOffset: 30, categories: const {
          'A': 60,
          'B': 20,
          'C': 51,
          'D': 49,
        }),
      ]));

      expect(found.length, 2);
      expect(found.first.kind, InsightKind.overallImproved);
    });

    test('the same history always reads the same way', () {
      final s = series([
        point(70, dayOffset: 0, categories: const {'Zeta': 50, 'Alpha': 50}),
        point(75, dayOffset: 30, categories: const {'Zeta': 60, 'Alpha': 60}),
      ]);

      expect(calculator(s), calculator(s));
    });
  });

  group('achievements', () {
    const calculator = AchievementCalculator();

    test('nothing recorded earns nothing', () {
      expect(calculator(const AssessmentSeries.empty('p1')), isEmpty);
    });

    test('the first assessment earns its milestone at its own date', () {
      final earned = calculator(series([point(40, dayOffset: 0)]));

      expect(earned.single.kind, AchievementKind.firstAssessment);
      expect(earned.single.earnedAt, epoch);
    });

    test('a count milestone is dated by the observation that reached it', () {
      final earned = calculator(series([
        point(40, dayOffset: 0),
        point(42, dayOffset: 30),
        point(44, dayOffset: 60),
      ]));

      final three = earned.firstWhere(
        (a) => a.kind == AchievementKind.threeAssessments,
      );
      expect(three.earnedAt, epoch.add(const Duration(days: 60)));
    });

    test('excellent health is dated the first time it was reached', () {
      // A milestone records when something was achieved, not the last time
      // it happened to be true.
      final earned = calculator(series([
        point(50, dayOffset: 0),
        point(90, dayOffset: 30, band: HealthCategory.excellent),
        point(92, dayOffset: 60, band: HealthCategory.excellent),
      ]));

      final excellent = earned.firstWhere(
        (a) => a.kind == AchievementKind.excellentHealth,
      );
      expect(excellent.earnedAt, epoch.add(const Duration(days: 30)));
    });

    test('a ten point gain over the first score earns its milestone', () {
      final earned = calculator(series([
        point(50, dayOffset: 0),
        point(58, dayOffset: 30),
        point(61, dayOffset: 60),
      ]));

      expect(
        earned.map((a) => a.kind),
        contains(AchievementKind.tenPercentImprovement),
      );
    });

    test('a gain that never reaches ten points earns nothing', () {
      final earned = calculator(series([
        point(50, dayOffset: 0),
        point(55, dayOffset: 30),
      ]));

      expect(
        earned.map((a) => a.kind),
        isNot(contains(AchievementKind.tenPercentImprovement)),
      );
    });

    test('five consecutive rises earn the streak milestone', () {
      final earned = calculator(series([
        for (var i = 0; i < 6; i++) point(40 + i * 3, dayOffset: i * 30),
      ]));

      expect(
        earned.map((a) => a.kind),
        contains(AchievementKind.fiveConsecutiveImprovements),
      );
    });

    test('a break in the run costs the streak milestone', () {
      final earned = calculator(series([
        point(40, dayOffset: 0),
        point(43, dayOffset: 30),
        point(43, dayOffset: 60),
        point(46, dayOffset: 90),
        point(49, dayOffset: 120),
        point(52, dayOffset: 150),
      ]));

      expect(
        earned.map((a) => a.kind),
        isNot(contains(AchievementKind.fiveConsecutiveImprovements)),
      );
    });

    test('milestones come back oldest first', () {
      final earned = calculator(series([
        point(50, dayOffset: 0),
        point(70, dayOffset: 30),
        point(90, dayOffset: 60, band: HealthCategory.excellent),
      ]));

      for (var i = 1; i < earned.length; i++) {
        expect(
          earned[i].earnedAt.isBefore(earned[i - 1].earnedAt),
          isFalse,
          reason: 'milestones must be in chronological order',
        );
      }
    });
  });
}
