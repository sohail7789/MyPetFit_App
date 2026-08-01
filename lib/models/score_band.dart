import 'package:flutter/material.dart';
import '../config/assets.dart';
import '../config/theme.dart';
import 'score_result.dart';

/// Presentation values for each score band, transcribed from `BANDS` in
/// "MyPetFit Assessment.dc.html".
extension ScoreBand on HealthCategory {
  Color get bandColor => switch (this) {
        HealthCategory.critical => AppTheme.critical,
        HealthCategory.needsImprovement => AppTheme.warning,
        HealthCategory.good => AppTheme.success,
        HealthCategory.excellent => AppTheme.info,
      };

  Color get bandTint => switch (this) {
        HealthCategory.critical => AppTheme.bandCriticalTint,
        HealthCategory.needsImprovement => AppTheme.bandNeedsTint,
        HealthCategory.good => AppTheme.bandGoodTint,
        HealthCategory.excellent => AppTheme.bandExcellentTint,
      };

  Color get bandLine => switch (this) {
        HealthCategory.critical => AppTheme.bandCriticalLine,
        HealthCategory.needsImprovement => AppTheme.bandNeedsLine,
        HealthCategory.good => AppTheme.bandGoodLine,
        HealthCategory.excellent => AppTheme.bandExcellentLine,
      };

  /// Glyph shown in the band chip. Rendered as an icon rather than a text
  /// character — Inter has no coverage for ✓/★, which show as tofu.
  IconData get bandGlyph => switch (this) {
        HealthCategory.critical => Icons.priority_high_rounded,
        HealthCategory.needsImprovement => Icons.arrow_forward_rounded,
        HealthCategory.good => Icons.check_rounded,
        HealthCategory.excellent => Icons.star_rounded,
      };

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
Color categoryBarColor(double percent) {
  if (percent <= 25) return AppTheme.critical;
  if (percent <= 50) return AppTheme.warning;
  if (percent <= 75) return AppTheme.success;
  return AppTheme.info;
}
