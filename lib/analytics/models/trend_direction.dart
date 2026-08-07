/// Which way a score has moved, once noise is discounted.
enum TrendDirection {
  improving,
  declining,

  /// Moved, but by less than the questionnaire can meaningfully resolve.
  stable,

  /// Nothing to compare against. Distinct from [stable] on purpose: "we
  /// cannot say" and "it has not changed" are different claims, and a health
  /// product must not make the second when it only has grounds for the first.
  unknown,
}

/// The movement treated as indistinguishable from no movement, in points.
///
/// The assessment is 45 questions normalised to 0–100, so a single answer
/// moves the total by roughly a point. Two points is inside answer-to-answer
/// noise — an owner who guesses one question differently should not be told
/// their pet's health changed direction.
///
/// A parameter rather than a constant at every call site, so a clinical
/// consumer can tighten it without forking the calculation.
const int kDefaultStableBand = 2;

/// Classifies a change of [deltaPoints].
///
/// [stableBand] is inclusive: a move of exactly the band reads as stable.
TrendDirection directionForDelta(
  int deltaPoints, {
  int stableBand = kDefaultStableBand,
}) {
  if (deltaPoints.abs() <= stableBand) return TrendDirection.stable;
  return deltaPoints > 0 ? TrendDirection.improving : TrendDirection.declining;
}
