import 'achievement.dart';
import 'analytics_summary.dart';
import 'assessment_series.dart';
import 'category_trend.dart';
import 'health_insight.dart';

/// Everything analytics has to say about one subject, computed once.
///
/// A single immutable value rather than a bag of calculators the UI calls
/// during build: a screen holding this cannot accidentally re-derive a trend
/// per frame, and a vet portal, a web dashboard or a premium report can be
/// handed the same object over a wire.
class AnalyticsSnapshot {
  /// The history this was computed from. Kept so a consumer can reach the
  /// underlying observations — a graph needs the points, and a tap needs the
  /// id to navigate by.
  final AssessmentSeries series;

  final AnalyticsSummary summary;

  /// Worst movement first.
  final List<CategoryTrend> categoryTrends;

  /// Highest weight first, capped.
  final List<HealthInsight> insights;

  /// Oldest earned first.
  final List<Achievement> achievements;

  const AnalyticsSnapshot({
    required this.series,
    required this.summary,
    this.categoryTrends = const [],
    this.insights = const [],
    this.achievements = const [],
  });

  /// A subject with nothing recorded. Every list empty, no trend claimed.
  factory AnalyticsSnapshot.empty(String subjectId) => AnalyticsSnapshot(
        series: AssessmentSeries.empty(subjectId),
        summary: AnalyticsSummary.none,
      );

  bool get hasHistory => series.isNotEmpty;

  /// True once there is enough history to draw a direction from.
  ///
  /// The gate every trend surface should check before rendering. One
  /// observation earns an invitation to take another, not a graph.
  bool get hasTrend => series.hasTrend;

  int get assessmentCount => series.length;
}
