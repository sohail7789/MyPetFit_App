/// Plain numbers over a subject's history.
///
/// No interpretation and no clock: everything here is derived from the
/// stored observations alone, so the same history always produces the same
/// statistics no matter when it is asked.
class AnalyticsStatistics {
  final int assessmentCount;

  /// Null only when there is no history at all.
  final int? bestScore;
  final int? worstScore;
  final int? latestScore;

  /// Mean of every stored score. Kept as a double — rounding is the
  /// presentation layer's decision, and rounding here would lose the
  /// difference between 74.5 and 74.
  final double? averageScore;

  final DateTime? firstAssessmentAt;
  final DateTime? latestAssessmentAt;

  /// Days from the first observation to the most recent one.
  ///
  /// The span actually covered by the record, not "days since you started",
  /// which would need a clock and would change between two reads of the same
  /// history. A screen wanting the latter can compute it from
  /// [firstAssessmentAt] against its own `now`.
  final int trackingSpanDays;

  const AnalyticsStatistics({
    required this.assessmentCount,
    this.bestScore,
    this.worstScore,
    this.latestScore,
    this.averageScore,
    this.firstAssessmentAt,
    this.latestAssessmentAt,
    this.trackingSpanDays = 0,
  });

  static const AnalyticsStatistics none =
      AnalyticsStatistics(assessmentCount: 0);

  bool get hasHistory => assessmentCount > 0;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsStatistics &&
      other.assessmentCount == assessmentCount &&
      other.bestScore == bestScore &&
      other.worstScore == worstScore &&
      other.latestScore == latestScore &&
      other.averageScore == averageScore &&
      other.firstAssessmentAt == firstAssessmentAt &&
      other.latestAssessmentAt == latestAssessmentAt &&
      other.trackingSpanDays == trackingSpanDays;

  @override
  int get hashCode => Object.hash(
        assessmentCount,
        bestScore,
        worstScore,
        latestScore,
        averageScore,
        firstAssessmentAt,
        latestAssessmentAt,
        trackingSpanDays,
      );
}
