import '../models/assessment_series.dart';
import '../models/category_trend.dart';

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

    final trends = [
      for (final entry in byName.entries)
        CategoryTrend(name: entry.key, points: entry.value),
    ];

    trends.sort((a, b) {
      final da = a.delta;
      final db = b.delta;

      if (da == null && db == null) return a.name.compareTo(b.name);
      if (da == null) return 1;
      if (db == null) return -1;

      final byDelta = da.compareTo(db);
      return byDelta != 0 ? byDelta : a.name.compareTo(b.name);
    });

    return trends;
  }
}
