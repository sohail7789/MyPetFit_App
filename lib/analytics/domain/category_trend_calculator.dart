import '../models/assessment_series.dart';
import '../models/category_trend.dart';
import 'category_sort.dart';

/// Turns a history into one trend per health area.
class CategoryTrendCalculator {
  const CategoryTrendCalculator();

  /// Every category the subject has ever been scored on, worst movement
  /// first.
  ///
  /// Sorted so the areas needing attention lead: a decline of nine ranks
  /// above a decline of three, which ranks above any improvement. Categories
  /// measured only once carry no movement and settle at the end — they are
  /// not neutral news, they are no news. Ties break on name so the order
  /// cannot shuffle between two reads of the same history.
  List<CategoryTrend> call(AssessmentSeries series) {
    final byName = <String, List<CategoryPoint>>{};

    for (final point in series.points) {
      for (final entry in point.categoryScores.entries) {
        byName.putIfAbsent(entry.key, () => []).add(
              CategoryPoint(
                pointId: point.id,
                takenAt: point.takenAt,
                score: entry.value,
              ),
            );
      }
    }

    // Ordered by the shared comparator rather than a copy of the rule here:
    // "worst decline first" is stated once, so a caller asking for it
    // through CategorySortMode and this default cannot drift apart.
    return sortCategoryTrends([
      for (final entry in byName.entries)
        CategoryTrend(name: entry.key, points: entry.value),
    ]);
  }
}
