import '../models/assessment_series.dart';
import '../models/health_insight.dart';
import '../models/insight_severity.dart';
import '../models/trend_direction.dart';
import 'category_trend_calculator.dart';
import 'trend_calculator.dart';

/// Deterministic findings about what changed since the last assessment.
///
/// Every insight is arithmetic over stored values. Nothing is generated,
/// inferred or phrased here — the output is a list of facts with a severity
/// and an ordering weight, and the words are the formatter's problem.
///
/// **One time frame throughout: the previous assessment to the latest.**
/// The overall figure and the category figures used to disagree — one
/// compared the last two reports, the other the whole record — so the same
/// section could show "+3 overall" beside "+19 in one area" and read as an
/// arithmetic error. Whole-history evolution is what the category cards
/// answer; this answers what changed most recently, which is a different
/// question deserving its own consistent window.
class InsightCalculator {
  final TrendCalculator trend;
  final CategoryTrendCalculator categories;
  final int stableBand;

  /// A decline of this many points or more leads rather than merely being
  /// noted. Roughly a tenth of the scale — large enough that a reader should
  /// not have to find it among other findings.
  final int alertDecline;

  /// How many findings to return.
  ///
  /// A capped, weighted list rather than everything: nine categories would
  /// produce nine insights and bury the two that matter. Callers wanting the
  /// full picture read the category trends directly.
  final int limit;

  const InsightCalculator({
    this.trend = const TrendCalculator(),
    this.categories = const CategoryTrendCalculator(),
    this.stableBand = kDefaultStableBand,
    this.alertDecline = 10,
    this.limit = 4,
  });

  List<HealthInsight> call(AssessmentSeries series) {
    if (series.isEmpty) return const [];

    if (!series.hasTrend) {
      // One observation is a starting point, not a trend. Saying so is
      // better than saying nothing, and far better than inventing movement.
      return const [
        HealthInsight(
          kind: InsightKind.firstAssessmentRecorded,
          weight: 1000,
          severity: InsightSeverity.neutral,
        ),
      ];
    }

    final found = <HealthInsight>[
      _overall(series),
      ..._categories(series),
    ];

    found.sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      // Stable ordering for equal weights, so the same history always reads
      // in the same order.
      final byKind = a.kind.index.compareTo(b.kind.index);
      return byKind != 0 ? byKind : (a.subject ?? '').compareTo(b.subject ?? '');
    });

    return found.take(limit).toList();
  }

  HealthInsight _overall(AssessmentSeries series) {
    final change = trend.changeSincePrevious(series)!;
    final direction = directionForDelta(change, stableBand: stableBand);

    return HealthInsight(
      kind: switch (direction) {
        TrendDirection.improving => InsightKind.overallImproved,
        TrendDirection.declining => InsightKind.overallDeclined,
        _ => InsightKind.overallStable,
      },
      deltaPoints: change,
      // Always outranks a single category: the headline is the pet, and the
      // areas explain it.
      weight: 500 + change.abs(),
      severity: _severityFor(direction, change),
    );
  }

  /// The areas that moved between the last two assessments.
  ///
  /// A category is only considered when it was measured in the newest
  /// assessment. One dropped from the questionnaire, or simply not scored
  /// this time, has no recent change — and reporting its older movement as
  /// though it were recent would be the same mistake in miniature that this
  /// calculator was just fixed for.
  List<HealthInsight> _categories(AssessmentSeries series) {
    final latestId = series.latest!.id;
    final moved = <({String name, int delta})>[];

    for (final trend in categories(series)) {
      final points = trend.points;
      if (points.length < 2) continue;
      if (points.last.pointId != latestId) continue;

      // Rounded at each end before subtracting, so a delta can never
      // contradict the figures a card displays.
      final delta = points.last.score.round() -
          points[points.length - 2].score.round();
      if (delta.abs() <= stableBand) continue;

      moved.add((name: trend.name, delta: delta));
    }

    if (moved.isEmpty) return const [];

    moved.sort((a, b) {
      final byDelta = a.delta.compareTo(b.delta);
      return byDelta != 0 ? byDelta : a.name.compareTo(b.name);
    });

    final declines = moved.where((m) => m.delta < 0).toList();
    final improvements = moved.where((m) => m.delta > 0).toList();

    return [
      if (declines.isNotEmpty)
        _categoryInsight(
          declines.first,
          // "Declined the most" only means anything when something else
          // also declined; with one, it is just a decline.
          superlative: declines.length > 1,
        ),
      if (improvements.isNotEmpty)
        _categoryInsight(
          improvements.last,
          superlative: improvements.length > 1,
        ),
    ];
  }

  HealthInsight _categoryInsight(
    ({String name, int delta}) entry, {
    required bool superlative,
  }) {
    final direction = directionForDelta(entry.delta, stableBand: stableBand);
    final declining = entry.delta < 0;

    return HealthInsight(
      kind: switch ((declining, superlative)) {
        (true, true) => InsightKind.categoryDeclinedMost,
        (true, false) => InsightKind.categoryDeclined,
        (false, true) => InsightKind.categoryImprovedMost,
        (false, false) => InsightKind.categoryImproved,
      },
      subject: entry.name,
      deltaPoints: entry.delta,
      weight: entry.delta.abs(),
      severity: _severityFor(direction, entry.delta),
    );
  }

  InsightSeverity _severityFor(TrendDirection direction, int delta) =>
      switch (direction) {
        TrendDirection.improving => InsightSeverity.positive,
        TrendDirection.declining => delta.abs() >= alertDecline
            ? InsightSeverity.alert
            : InsightSeverity.caution,
        _ => InsightSeverity.neutral,
      };
}
