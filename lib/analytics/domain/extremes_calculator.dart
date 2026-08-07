import '../models/assessment_series.dart';
import '../models/trend_extremes.dart';

/// Finds the observations a trend surface should call out.
///
/// Thin by design — the rule lives on [TrendExtremes.of] so the value can be
/// built without reaching for a calculator, and this exists so the engine
/// composes the same way for every part of a snapshot.
class ExtremesCalculator {
  const ExtremesCalculator();

  TrendExtremes? call(AssessmentSeries series) => TrendExtremes.of(series);
}
