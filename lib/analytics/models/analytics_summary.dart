import '../../models/score_result.dart' show HealthCategory;
import 'analytics_statistics.dart';
import 'trend_direction.dart';

/// The headline answer to "how is my pet doing?".
///
/// Composed rather than computed: the statistics are the numbers, the
/// direction is the judgement, and this is the pair a summary card, a vet
/// portal header and a premium report all need.
class AnalyticsSummary {
  final AnalyticsStatistics statistics;

  /// The most recent stored band, or null with no history.
  final HealthCategory? currentBand;

  /// Movement from the previous observation to the latest one.
  ///
  /// [TrendDirection.unknown] until there are two to compare — never
  /// [TrendDirection.stable], which would claim nothing changed.
  final TrendDirection direction;

  /// Points gained or lost since the previous observation. Null when there
  /// is no previous one.
  final int? changeSincePrevious;

  /// Points gained or lost across the whole recorded history.
  final int? changeSinceFirst;

  const AnalyticsSummary({
    required this.statistics,
    this.currentBand,
    this.direction = TrendDirection.unknown,
    this.changeSincePrevious,
    this.changeSinceFirst,
  });

  static const AnalyticsSummary none =
      AnalyticsSummary(statistics: AnalyticsStatistics.none);

  bool get hasHistory => statistics.hasHistory;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsSummary &&
      other.statistics == statistics &&
      other.currentBand == currentBand &&
      other.direction == direction &&
      other.changeSincePrevious == changeSincePrevious &&
      other.changeSinceFirst == changeSinceFirst;

  @override
  int get hashCode => Object.hash(
        statistics,
        currentBand,
        direction,
        changeSincePrevious,
        changeSinceFirst,
      );
}
