import '../models/category_trend.dart';

/// How a set of category trends should be ordered.
///
/// A rule, not a preference, which is why it lives in the domain rather than
/// being a widget's business: a veterinarian portal ranking by current
/// health and a consumer app ranking by movement are asking different
/// questions of the same data, and both deserve the same answer everywhere
/// they ask it.
enum CategorySortMode {
  /// Steepest fall first. What needs attention leads.
  largestDeclineFirst,

  /// Steepest rise first. What is working leads.
  largestImprovementFirst,

  /// Weakest current score first, regardless of which way it moved.
  lowestCurrentScoreFirst,

  /// By name. For a reader comparing two reports side by side.
  alphabetical,
}

/// Orders [trends] by [mode], leaving the input untouched.
///
/// Categories measured only once carry no movement, so under a
/// movement-based order they cannot be ranked against ones that do. They
/// settle at the end — not because they are unimportant, but because "no
/// news" is not a small change and pretending otherwise would put them in
/// the middle of the list as though they had held steady.
///
/// Every mode breaks ties on the category name, so the same history always
/// renders in the same order — a list that reshuffles between two reads of
/// unchanged data reads as a defect.
List<CategoryTrend> sortCategoryTrends(
  List<CategoryTrend> trends, {
  CategorySortMode mode = CategorySortMode.largestDeclineFirst,
}) {
  final sorted = [...trends];

  sorted.sort((a, b) {
    final byMode = switch (mode) {
      CategorySortMode.largestDeclineFirst => _byDelta(a, b, ascending: true),
      CategorySortMode.largestImprovementFirst =>
        _byDelta(a, b, ascending: false),
      CategorySortMode.lowestCurrentScoreFirst => _byLatest(a, b),
      CategorySortMode.alphabetical => 0,
    };

    return byMode != 0 ? byMode : a.name.compareTo(b.name);
  });

  return sorted;
}

int _byDelta(CategoryTrend a, CategoryTrend b, {required bool ascending}) {
  final da = a.delta;
  final db = b.delta;

  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;

  return ascending ? da.compareTo(db) : db.compareTo(da);
}

int _byLatest(CategoryTrend a, CategoryTrend b) {
  final la = a.latest;
  final lb = b.latest;

  if (la == null && lb == null) return 0;
  if (la == null) return 1;
  if (lb == null) return -1;

  return la.compareTo(lb);
}
