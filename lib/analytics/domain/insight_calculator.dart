import '../models/assessment_series.dart';
import '../models/category_trend.dart';
import '../models/health_insight.dart';
import '../models/trend_direction.dart';
import 'category_trend_calculator.dart';
import 'trend_calculator.dart';

/// Deterministic findings about a subject's history.
///
/// Every insight is arithmetic over stored values. Nothing is generated,
/// inferred or phrased here — the output is a list of facts, ordered by how
/// much they moved, and the words are somebody else's problem.
class InsightCalculator {
  final TrendCalculator trend;
  final CategoryTrendCalculator categories;
  final int stableBand;

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
    this.limit = 4,
  });

  List<HealthInsight> call(AssessmentSeries series) {
    if (series.isEmpty) return const [];

    if (!series.hasTrend) {
      // One observation is a starting point, not a trend. Saying so is
      // better than saying nothing, and far better than inventing movement.
      return [
        HealthInsight(
          kind: InsightKind.firstAssessmentRecorded,
          weight: 1000,
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
    );
  }

  List<HealthInsight> _categories(AssessmentSeries series) {
    final trends = categories(series).where((t) => t.hasTrend).toList();
    if (trends.isEmpty) return const [];

    // Already sorted worst movement first by the calculator.
    final worst = trends.first;
    final best = trends.last;

    final found = <HealthInsight>[];

    if (_moved(worst)) {
      found.add(
        HealthInsight(
          kind: worst.delta! < 0
              ? InsightKind.categoryDeclinedMost
              : InsightKind.categoryImproved,
          subject: worst.name,
          deltaPoints: worst.delta,
          weight: worst.delta!.abs(),
        ),
      );
    }

    // Only when it is a different area — with one moving category, calling
    // it both the biggest rise and the biggest fall reads as a bug.
    if (best.name != worst.name && _moved(best)) {
      found.add(
        HealthInsight(
          kind: best.delta! > 0
              ? InsightKind.categoryImprovedMost
              : InsightKind.categoryDeclined,
          subject: best.name,
          deltaPoints: best.delta,
          weight: best.delta!.abs(),
        ),
      );
    }

    return found;
  }

  bool _moved(CategoryTrend trend) {
    final delta = trend.delta;
    return delta != null && delta.abs() > stableBand;
  }
}
