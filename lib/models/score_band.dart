import 'package:flutter/material.dart';
import '../config/assets.dart';
import '../config/theme.dart';
import 'score_result.dart';

/// Presentation values for each score band, transcribed from `BANDS` in
/// "MyPetFit Assessment.dc.html" and its dark counterpart.
///
/// The three colour accessors take an [AppColors] rather than being getters
/// because each band resolves differently in light and dark. They take the
/// palette itself, not a [BuildContext], so the shared report PDF can ask for
/// [AppColors.light] explicitly — a document that gets printed or forwarded
/// should not follow the reader's screen appearance.
extension ScoreBand on HealthCategory {
  /// The band's accent, used for the score figure, chip glyph and bar fill.
  ///
  /// Reads the `…Text` accents rather than the fills: `BANDS` in the dark
  /// design uses the brightened #F0A05F / #66D68C, which is what stays legible
  /// drawn directly on the canvas. In light both variants are the same colour.
  Color bandColor(AppColors c) => switch (this) {
        HealthCategory.critical => c.critical,
        HealthCategory.needsImprovement => c.warningText,
        HealthCategory.good => c.successText,
        HealthCategory.excellent => c.info,
      };

  Color bandTint(AppColors c) => switch (this) {
        HealthCategory.critical => c.bandCriticalTint,
        HealthCategory.needsImprovement => c.bandNeedsTint,
        HealthCategory.good => c.bandGoodTint,
        HealthCategory.excellent => c.bandExcellentTint,
      };

  Color bandLine(AppColors c) => switch (this) {
        HealthCategory.critical => c.bandCriticalLine,
        HealthCategory.needsImprovement => c.bandNeedsLine,
        HealthCategory.good => c.bandGoodLine,
        HealthCategory.excellent => c.bandExcellentLine,
      };

  /// Glyph shown in the band chip. Rendered as an icon rather than a text
  /// character — Inter has no coverage for ✓/★, which show as tofu.
  IconData get bandGlyph => switch (this) {
        HealthCategory.critical => Icons.priority_high_rounded,
        HealthCategory.needsImprovement => Icons.arrow_forward_rounded,
        HealthCategory.good => Icons.check_rounded,
        HealthCategory.excellent => Icons.star_rounded,
      };

  /// True for Good and Excellent — the bands the report card celebrates.
  bool get isPositive =>
      this == HealthCategory.good || this == HealthCategory.excellent;

  /// The lower bands show the concerned puppy; the upper two celebrate.
  String get bandArt => switch (this) {
        HealthCategory.critical ||
        HealthCategory.needsImprovement =>
          AppAssets.vetAlert,
        HealthCategory.good || HealthCategory.excellent => AppAssets.greatJob,
      };

  String get bandCopy => switch (this) {
        HealthCategory.critical =>
          'This score suggests your pet needs veterinary attention soon. It is '
              'not a diagnosis — take the report to your vet and go through it '
              'together.',
        HealthCategory.needsImprovement =>
          'There is real room to improve. A few steady changes in the weakest '
              'categories will move this score quickly.',
        HealthCategory.good =>
          'Your pet is in good shape. Keep the routine steady and tighten the '
              'one or two categories that trail behind.',
        HealthCategory.excellent =>
          "Excellent — your pet's care routine is working. This is the level "
              'to maintain, not exceed.',
      };

  String get bandAdvice => switch (this) {
        HealthCategory.critical =>
          'Book a veterinary consultation this week. Bring this report card; '
              'the lowest categories below show what to raise first.',
        HealthCategory.needsImprovement =>
          'Pick the two lowest categories below and change one habit in each '
              'for a month, then retake the assessment.',
        HealthCategory.good =>
          'Hold the current routine and target your lowest category. Retake in '
              '3 months to confirm the trend.',
        HealthCategory.excellent =>
          'Keep everything as it is. Retake every 3 months so any drift shows '
              'up early.',
      };
}

/// Colour for a single category's breakdown bar, using the same cutoffs as
/// the overall bands.
Color categoryBarColor(AppColors c, double percent) {
  if (percent <= 25) return c.critical;
  if (percent <= 50) return c.warningText;
  if (percent <= 75) return c.successText;
  return c.info;
}
