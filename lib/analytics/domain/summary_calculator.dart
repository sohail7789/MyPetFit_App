import '../models/analytics_summary.dart';
import '../models/assessment_series.dart';
import 'statistics_calculator.dart';
import 'trend_calculator.dart';

/// Composes the statistics and the trend into one headline value.
class SummaryCalculator {
  final StatisticsCalculator statistics;
  final TrendCalculator trend;

  const SummaryCalculator({
    this.statistics = const StatisticsCalculator(),
    this.trend = const TrendCalculator(),
  });

  AnalyticsSummary call(AssessmentSeries series) {
    if (series.isEmpty) return AnalyticsSummary.none;

    return AnalyticsSummary(
      statistics: statistics(series),
      currentBand: series.latest!.band,
      direction: trend.direction(series),
      changeSincePrevious: trend.changeSincePrevious(series),
      changeSinceFirst: trend.changeSinceFirst(series),
    );
  }
}
