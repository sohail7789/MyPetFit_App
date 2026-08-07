import '../models/analytics_snapshot.dart';
import '../models/assessment_series.dart';
import 'analytics_engine.dart';

/// Computes a snapshot once per version of a history.
///
/// Analysis is O(points x categories) and a Flutter build can run many times
/// a second. With five stored assessments that is free; with the ten years of
/// history this module is meant to survive, recomputing per frame while a
/// graph animates is exactly the cost that makes an analytics screen feel
/// cheap. Keyed on [AssessmentSeries.identity], which changes whenever the
/// history does and never requires walking it.
///
/// Holds one entry. Analytics is shown for the active subject, and switching
/// pets should not keep the previous pet's history alive.
class AnalyticsCache {
  final AnalyticsEngine engine;

  AnalyticsCache({this.engine = const AnalyticsEngine()});

  String? _key;
  AnalyticsSnapshot? _cached;

  AnalyticsSnapshot snapshotOf(AssessmentSeries series) {
    final key = series.identity;
    final cached = _cached;
    if (cached != null && _key == key) return cached;

    final computed = engine.analyse(series);
    _key = key;
    _cached = computed;
    return computed;
  }

  /// Drops the entry. Call on sign-out so one account's history is not held
  /// in memory under the next.
  void clear() {
    _key = null;
    _cached = null;
  }

  /// Whether [series] would be served from the cache. For tests and
  /// diagnostics.
  bool holds(AssessmentSeries series) =>
      _cached != null && _key == series.identity;
}
