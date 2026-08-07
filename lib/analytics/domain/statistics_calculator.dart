import '../models/analytics_statistics.dart';
import '../models/assessment_series.dart';

/// Plain numbers over a history. No clock, no interpretation.
class StatisticsCalculator {
  const StatisticsCalculator();

  AnalyticsStatistics call(AssessmentSeries series) {
    if (series.isEmpty) return AnalyticsStatistics.none;

    var best = series.points.first.score;
    var worst = series.points.first.score;
    var total = 0;

    for (final point in series.points) {
      if (point.score > best) best = point.score;
      if (point.score < worst) worst = point.score;
      total += point.score;
    }

    final firstAt = series.first!.takenAt;
    final latestAt = series.latest!.takenAt;

    return AnalyticsStatistics(
      assessmentCount: series.length,
      bestScore: best,
      worstScore: worst,
      latestScore: series.latest!.score,
      averageScore: total / series.length,
      firstAssessmentAt: firstAt,
      latestAssessmentAt: latestAt,
      // Clamped at zero so a clock-skewed record synced from another device
      // cannot report a negative span.
      trackingSpanDays:
          latestAt.difference(firstAt).inDays.clamp(0, 1 << 31).toInt(),
    );
  }
}
