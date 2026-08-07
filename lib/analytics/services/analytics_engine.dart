import '../domain/achievement_calculator.dart';
import '../domain/category_trend_calculator.dart';
import '../domain/insight_calculator.dart';
import '../domain/summary_calculator.dart';
import '../models/analytics_snapshot.dart';
import '../models/assessment_series.dart';

/// Runs the domain calculators over a history and assembles one snapshot.
///
/// The composition seam, deliberately thin. Calculators stay independently
/// usable — a portal wanting only a trend should not have to build insights
/// and achievements to get one — and this is the convenience for consumers
/// that want the lot.
///
/// Pure: same series in, equal snapshot out, no clock and no I/O.
class AnalyticsEngine {
  final SummaryCalculator summary;
  final CategoryTrendCalculator categoryTrends;
  final InsightCalculator insights;
  final AchievementCalculator achievements;

  const AnalyticsEngine({
    this.summary = const SummaryCalculator(),
    this.categoryTrends = const CategoryTrendCalculator(),
    this.insights = const InsightCalculator(),
    this.achievements = const AchievementCalculator(),
  });

  AnalyticsSnapshot analyse(AssessmentSeries series) {
    if (series.isEmpty) return AnalyticsSnapshot.empty(series.subjectId);

    return AnalyticsSnapshot(
      series: series,
      summary: summary(series),
      categoryTrends: categoryTrends(series),
      insights: insights(series),
      achievements: achievements(series),
    );
  }
}
