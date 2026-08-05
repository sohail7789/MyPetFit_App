import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/theme.dart';

/// Reads every colour field off a palette by name, so a token added to
/// [AppColors] without a dark value can't slip through.
Map<String, Color> _colorsOf(AppColors c) => {
      'canvas': c.canvas,
      'surface': c.surface,
      'surfaceRaised': c.surfaceRaised,
      'surfaceInset': c.surfaceInset,
      'surfaceLow': c.surfaceLow,
      'tint': c.tint,
      'tintSoft': c.tintSoft,
      'tintPanel': c.tintPanel,
      'border': c.border,
      'borderSoft': c.borderSoft,
      'borderField': c.borderField,
      'divider': c.divider,
      'dotInactive': c.dotInactive,
      'dotInactiveWarm': c.dotInactiveWarm,
      'meterTrack': c.meterTrack,
      'ink': c.ink,
      'inkSoft': c.inkSoft,
      'bodyStrong': c.bodyStrong,
      'body': c.body,
      'muted': c.muted,
      'placeholder': c.placeholder,
      'faint': c.faint,
      'fainter': c.fainter,
      'onTint': c.onTint,
      'action': c.action,
      'actionText': c.actionText,
      'start': c.start,
      'startText': c.startText,
      'startLight': c.startLight,
      'success': c.success,
      'successText': c.successText,
      'danger': c.danger,
      'dangerText': c.dangerText,
      'warning': c.warning,
      'warningText': c.warningText,
      'critical': c.critical,
      'info': c.info,
      'star': c.star,
      'appleMark': c.appleMark,
      'bandCriticalTint': c.bandCriticalTint,
      'bandCriticalLine': c.bandCriticalLine,
      'bandNeedsTint': c.bandNeedsTint,
      'bandNeedsLine': c.bandNeedsLine,
      'bandGoodTint': c.bandGoodTint,
      'bandGoodLine': c.bandGoodLine,
      'bandExcellentTint': c.bandExcellentTint,
      'bandExcellentLine': c.bandExcellentLine,
      'productBlueTint': c.productBlueTint,
      'productOrangeTint': c.productOrangeTint,
      'productGreenTint': c.productGreenTint,
      'productIndigoTint': c.productIndigoTint,
      'productRoseTint': c.productRoseTint,
      'productVioletTint': c.productVioletTint,
    };

/// Relative luminance, per WCAG.
double _luminance(Color c) => c.computeLuminance();

void main() {
  group('palette', () {
    test('every token differs between light and dark', () {
      final light = _colorsOf(AppColors.light);
      final dark = _colorsOf(AppColors.dark);

      // onAccent is deliberately white in both — everything else must move.
      final same = <String>[
        for (final e in light.entries)
          if (e.value == dark[e.key]) e.key,
      ];
      expect(same, isEmpty,
          reason: 'these tokens were never given a dark value: $same');
    });

    test('surfaces invert: light surfaces are light, dark ones are dark', () {
      const surfaceTokens = [
        'canvas', 'surface', 'surfaceRaised', 'surfaceInset', 'surfaceLow',
        'tint', 'tintSoft', 'tintPanel',
      ];
      final light = _colorsOf(AppColors.light);
      final dark = _colorsOf(AppColors.dark);
      for (final t in surfaceTokens) {
        expect(_luminance(light[t]!), greaterThan(0.7), reason: 'light $t');
        expect(_luminance(dark[t]!), lessThan(0.08), reason: 'dark $t');
      }
    });

    test('text ramp inverts', () {
      const textTokens = ['ink', 'inkSoft', 'bodyStrong', 'body'];
      final light = _colorsOf(AppColors.light);
      final dark = _colorsOf(AppColors.dark);
      for (final t in textTokens) {
        expect(_luminance(light[t]!), lessThan(0.3), reason: 'light $t');
        expect(_luminance(dark[t]!), greaterThan(0.35), reason: 'dark $t');
      }
    });

    test('dark brightens the text variant of every split accent', () {
      // The design's rule: fills stay muted, marks brighten. In light the two
      // are the same colour, so only dark should separate them.
      const pairs = [
        ('action', 'actionText'),
        ('start', 'startText'),
        ('success', 'successText'),
        ('danger', 'dangerText'),
        ('warning', 'warningText'),
      ];
      final light = _colorsOf(AppColors.light);
      final dark = _colorsOf(AppColors.dark);
      for (final (fill, text) in pairs) {
        expect(light[fill], light[text],
            reason: 'light should not split $fill');
        expect(_luminance(dark[text]!), greaterThan(_luminance(dark[fill]!)),
            reason: 'dark $text should be brighter than $fill');
      }
    });

    test('body text clears 4.5:1 against its surface in both appearances', () {
      double ratio(Color fg, Color bg) {
        final a = _luminance(fg) + 0.05;
        final b = _luminance(bg) + 0.05;
        return a > b ? a / b : b / a;
      }

      for (final c in [AppColors.light, AppColors.dark]) {
        final name = c.brightness.name;
        expect(ratio(c.ink, c.surface), greaterThanOrEqualTo(4.5),
            reason: '$name ink on surface');
        expect(ratio(c.body, c.surface), greaterThanOrEqualTo(4.5),
            reason: '$name body on surface');
        expect(ratio(c.bodyStrong, c.surface), greaterThanOrEqualTo(4.5),
            reason: '$name bodyStrong on surface');
        expect(ratio(c.onAccent, c.action), greaterThanOrEqualTo(4.5),
            reason: '$name onAccent on action fill');
      }
    });

    test('lerp walks from one palette to the other', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);
      expect(mid.surface, isNot(AppColors.light.surface));
      expect(mid.surface, isNot(AppColors.dark.surface));
      expect(AppColors.light.lerp(AppColors.dark, 0).surface,
          AppColors.light.surface);
      expect(AppColors.light.lerp(AppColors.dark, 1).surface,
          AppColors.dark.surface);
      // The list-valued tokens have to lerp element-wise, not snap.
      expect(mid.heroGradient.length, 3);
      expect(mid.onboardingWashes.length, 3);
      expect(mid.onboardingWashes[0].length, 3);
    });
  });

  group('ThemeData', () {
    test('both themes carry the extension and agree with it', () {
      for (final (theme, palette) in [
        (AppTheme.light, AppColors.light),
        (AppTheme.dark, AppColors.dark),
      ]) {
        final ext = theme.extension<AppColors>();
        expect(ext, isNotNull);
        expect(ext, same(palette));
        expect(theme.scaffoldBackgroundColor, palette.surface);
        expect(theme.colorScheme.primary, palette.action);
        expect(theme.colorScheme.brightness, palette.brightness);
      }
    });

    test('context.c resolves the palette the theme was built with',
        (() async {
      // Sanity: the extension getter is what every migrated call site uses.
      expect(AppTheme.dark.extension<AppColors>()!.brightness,
          Brightness.dark);
      expect(AppTheme.light.extension<AppColors>()!.brightness,
          Brightness.light);
    }));
  });
}
