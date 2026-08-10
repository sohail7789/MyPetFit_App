import 'package:flutter/material.dart';

/// Design tokens for the MyPetFit redesign.
///
/// Values are transcribed from the approved application design — the light
/// set from the main screen designs and the four component files they
/// import, the dark set from the dark-mode designs and their four dark
/// counterparts.
///
/// The two palettes were reconciled by aligning each light file against its
/// dark twin line by line, so every pairing below is the design's own and not
/// an approximation.
///
/// One structural difference between the two: in light a single hex served
/// both fills and text, while dark splits every accent into a muted fill and
/// a brightened text/icon variant (`action` vs [AppColors.actionText]). Use
/// the plain token when painting a surface, the `…Text` token when drawing
/// type or an icon directly on the canvas.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.surfaceLow,
    required this.tint,
    required this.tintSoft,
    required this.tintPanel,
    required this.border,
    required this.borderSoft,
    required this.borderField,
    required this.divider,
    required this.dotInactive,
    required this.meterTrack,
    required this.ink,
    required this.inkSoft,
    required this.bodyStrong,
    required this.body,
    required this.muted,
    required this.placeholder,
    required this.faint,
    required this.fainter,
    required this.onTint,
    required this.action,
    required this.actionText,
    required this.start,
    required this.startText,
    required this.startLight,
    required this.success,
    required this.successText,
    required this.danger,
    required this.dangerText,
    required this.warning,
    required this.warningText,
    required this.critical,
    required this.info,
    required this.star,
    required this.onAccent,
    required this.appleMark,
    required this.bandCriticalTint,
    required this.bandCriticalLine,
    required this.bandNeedsTint,
    required this.bandNeedsLine,
    required this.bandGoodTint,
    required this.bandGoodLine,
    required this.bandExcellentTint,
    required this.bandExcellentLine,
    required this.productBlueTint,
    required this.productOrangeTint,
    required this.productGreenTint,
    required this.productIndigoTint,
    required this.productRoseTint,
    required this.productVioletTint,
    required this.heroGradient,
    required this.onboardingWashes,
    required this.dotInactiveWarm,
    required this.shadowTone,
  });

  /// Which appearance this set paints. Lets widgets branch on the rare case
  /// where a value cannot be expressed as a token (e.g. an image overlay).
  final Brightness brightness;

  // ---------------------------------------------------------------------
  // Surfaces — dark steps up in tiers instead of stepping down from white
  // ---------------------------------------------------------------------

  /// Screen background behind the app surface.
  final Color canvas;

  /// Card / sheet surface.
  final Color surface;

  /// Surface lifted above a card — hero panels, highlighted rows.
  final Color surfaceRaised;

  /// Recessed surface — scroll wells, read-only panels.
  final Color surfaceInset;

  /// The faintest surface step, barely separated from [surface].
  final Color surfaceLow;

  /// Filled tint for selected chips, secondary buttons, active nav pill.
  final Color tint;

  /// Subtle tinted surface for pressed states and inset panels.
  final Color tintSoft;

  /// Very light tinted panel used on checkout / detail cards.
  final Color tintPanel;

  // Lines ---------------------------------------------------------------

  /// Standard hairline border.
  final Color border;

  /// Lighter hairline used for footers and dividers between rows.
  final Color borderSoft;

  /// Border around text inputs and outlined controls.
  final Color borderField;

  /// Divider used for the "or continue with" rules.
  final Color divider;

  /// Inactive pagination dot / toggle track.
  final Color dotInactive;

  /// Unfilled remainder of the password-strength meter.
  final Color meterTrack;

  // ---------------------------------------------------------------------
  // Text ramp
  // ---------------------------------------------------------------------

  /// Headings and high-emphasis text.
  final Color ink;

  /// Secondary headings, one step down from [ink].
  final Color inkSoft;

  /// Denser body copy inside cards.
  final Color bodyStrong;

  /// Body copy.
  final Color body;

  /// Muted meta text, uppercase section labels.
  final Color muted;

  /// Input placeholders and inactive marks.
  final Color placeholder;

  /// Low-emphasis marks — timeline rails, disabled glyphs.
  final Color faint;

  /// The lowest-emphasis mark in the ramp.
  final Color fainter;

  /// Type drawn on top of a [tint] fill.
  final Color onTint;

  // ---------------------------------------------------------------------
  // Accents — plain token fills, `…Text` variant draws type/icons
  // ---------------------------------------------------------------------

  /// Primary action colour — buttons, active nav, selected states.
  final Color action;

  /// Primary action as type or an icon on the canvas.
  final Color actionText;

  /// Secondary "start" colour — sign-up, place-order, celebratory CTAs.
  final Color start;

  /// Secondary "start" as type or an icon on the canvas.
  final Color startText;

  /// Lighter plum used for onboarding accents and password strength.
  final Color startLight;

  final Color success;
  final Color successText;
  final Color danger;
  final Color dangerText;
  final Color warning;
  final Color warningText;
  final Color critical;
  final Color info;
  final Color star;

  /// Type and icons sitting on a filled accent. White in both appearances.
  final Color onAccent;

  /// The Apple wordmark on the social sign-in button. Near-black on light,
  /// near-white on dark — Apple's mark is monochrome, so it has to invert
  /// rather than follow the indigo accents.
  final Color appleMark;

  // ---------------------------------------------------------------------
  // Score bands — mirrors BANDS in MyPetFit Assessment{,Dark}.dc.html
  // ---------------------------------------------------------------------

  final Color bandCriticalTint;
  final Color bandCriticalLine;
  final Color bandNeedsTint;
  final Color bandNeedsLine;
  final Color bandGoodTint;
  final Color bandGoodLine;
  final Color bandExcellentTint;
  final Color bandExcellentLine;

  // ---------------------------------------------------------------------
  // Product image panels — one tint per catalog category
  // ---------------------------------------------------------------------

  final Color productBlueTint;
  final Color productOrangeTint;
  final Color productGreenTint;
  final Color productIndigoTint;
  final Color productRoseTint;
  final Color productVioletTint;

  /// Three stops for the dashboard hero, indigo through rose.
  final List<Color> heroGradient;

  /// Top-to-bottom wash behind each of the three onboarding pages, three
  /// stops apiece. Page-specific in the design rather than derived from the
  /// surface ramp, so the exact stops are carried here.
  final List<List<Color>> onboardingWashes;

  /// Inactive pagination dot on the rose-washed onboarding page, which needs
  /// a warmer grey than [dotInactive] to sit on that background.
  final Color dotInactiveWarm;

  /// Base colour every elevation shadow is derived from. Light lifts with the
  /// ink tone; dark has nothing darker than the canvas to tint with, so it
  /// uses true black.
  final Color shadowTone;

  // ---------------------------------------------------------------------
  // Elevation
  // ---------------------------------------------------------------------

  /// Glow under the primary (action) CTA.
  List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: action.withValues(alpha: 0.42),
          blurRadius: 26,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Glow under the secondary (start) CTA.
  List<BoxShadow> get ctaShadowStart => [
        BoxShadow(
          color: start.withValues(alpha: 0.42),
          blurRadius: 26,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Soft lift under text fields.
  List<BoxShadow> get fieldShadow => [
        BoxShadow(
          color: shadowTone.withValues(alpha: 0.12),
          blurRadius: 6,
          spreadRadius: -4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Lift under floating circular back buttons.
  List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: shadowTone.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: -8,
          offset: const Offset(0, 6),
        ),
      ];

  // ---------------------------------------------------------------------
  // The two palettes
  // ---------------------------------------------------------------------

  static const AppColors light = AppColors(
    brightness: Brightness.light,
    canvas: Color(0xFFF1F0F6),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF4F1F9),
    surfaceInset: Color(0xFFF7F5FA),
    surfaceLow: Color(0xFFFCFBFD),
    tint: Color(0xFFEFECF5),
    tintSoft: Color(0xFFF7F5FA),
    tintPanel: Color(0xFFF8F7FB),
    border: Color(0xFFE6E4EF),
    borderSoft: Color(0xFFF0EEF6),
    borderField: Color(0xFFC9C6D9),
    divider: Color(0xFFEAE8F1),
    dotInactive: Color(0xFFD8D5E6),
    meterTrack: Color(0xFFE4E1EE),
    ink: Color(0xFF2A2C5A),
    inkSoft: Color(0xFF3A3A66),
    bodyStrong: Color(0xFF4A4A72),
    body: Color(0xFF6B6D8F),
    muted: Color(0xFF8A8AA6),
    placeholder: Color(0xFF9B9BB4),
    faint: Color(0xFFB0AEC2),
    fainter: Color(0xFFB7B3CE),
    onTint: Color(0xFF383567),
    action: Color(0xFF46437F),
    actionText: Color(0xFF46437F),
    start: Color(0xFF8E4F7C),
    startText: Color(0xFF8E4F7C),
    startLight: Color(0xFFA76A96),
    success: Color(0xFF2E7D46),
    successText: Color(0xFF2E7D46),
    danger: Color(0xFFB0475A),
    dangerText: Color(0xFFB0475A),
    warning: Color(0xFFC25A20),
    warningText: Color(0xFFC25A20),
    critical: Color(0xFFC62828),
    info: Color(0xFF1E6FA8),
    star: Color(0xFFC9A227),
    onAccent: Color(0xFFFFFFFF),
    appleMark: Color(0xFF111111),
    bandCriticalTint: Color(0xFFFBF0F0),
    bandCriticalLine: Color(0xFFF0D6D6),
    bandNeedsTint: Color(0xFFFDF4EE),
    bandNeedsLine: Color(0xFFF2E0D2),
    bandGoodTint: Color(0xFFF1F8F3),
    bandGoodLine: Color(0xFFD9EADF),
    bandExcellentTint: Color(0xFFEFF5FB),
    bandExcellentLine: Color(0xFFD5E4F1),
    productBlueTint: Color(0xFFEAF3FC),
    productOrangeTint: Color(0xFFFDF4EE),
    productGreenTint: Color(0xFFF1F8F3),
    productIndigoTint: Color(0xFFF3F0F9),
    productRoseTint: Color(0xFFF7EFF4),
    productVioletTint: Color(0xFFEFEEF8),
    heroGradient: [Color(0xFF46437F), Color(0xFF5B4E8E), Color(0xFF8E4F7C)],
    onboardingWashes: [
      [Color(0xFFF3F0F9), Color(0xFFF8F6FB), Color(0xFFFFFFFF)],
      [Color(0xFFF7EFF4), Color(0xFFFBF6F9), Color(0xFFFFFFFF)],
      [Color(0xFFEFEEF8), Color(0xFFF7F6FB), Color(0xFFFFFFFF)],
    ],
    dotInactiveWarm: Color(0xFFE4D9E2),
    shadowTone: Color(0xFF2A2C5A),
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    canvas: Color(0xFF0D0C14),
    surface: Color(0xFF1D1B27),
    surfaceRaised: Color(0xFF252332),
    surfaceInset: Color(0xFF232130),
    surfaceLow: Color(0xFF211F2C),
    tint: Color(0xFF2B2838),
    tintSoft: Color(0xFF232130),
    tintPanel: Color(0xFF232130),
    border: Color(0xFF2E2B3C),
    borderSoft: Color(0xFF232130),
    borderField: Color(0xFF443F58),
    divider: Color(0xFF2C2939),
    dotInactive: Color(0xFF38344A),
    meterTrack: Color(0xFF332F43),
    ink: Color(0xFFEDEBF7),
    inkSoft: Color(0xFFDAD6EC),
    bodyStrong: Color(0xFFC8C4D8),
    body: Color(0xFFA29EB6),
    muted: Color(0xFF8E8AA4),
    placeholder: Color(0xFF7C7893),
    faint: Color(0xFF6D6885),
    fainter: Color(0xFF5A5474),
    onTint: Color(0xFFBDB8F5),
    action: Color(0xFF5B54B8),
    actionText: Color(0xFFA9A3F0),
    start: Color(0xFFA85D91),
    startText: Color(0xFFE7A0CA),
    startLight: Color(0xFFE7A0CA),
    success: Color(0xFF2F8A4E),
    successText: Color(0xFF66D68C),
    danger: Color(0xFFC4536A),
    dangerText: Color(0xFFF0909F),
    warning: Color(0xFFC2661F),
    warningText: Color(0xFFF0A05F),
    critical: Color(0xFFF0736D),
    info: Color(0xFF5AAEE8),
    star: Color(0xFFE8C24A),
    onAccent: Color(0xFFFFFFFF),
    appleMark: Color(0xFFEDEBF6),
    bandCriticalTint: Color(0xFF2E1D1D),
    bandCriticalLine: Color(0xFF3A2323),
    bandNeedsTint: Color(0xFF2A211A),
    bandNeedsLine: Color(0xFF33261D),
    bandGoodTint: Color(0xFF16241B),
    bandGoodLine: Color(0xFF1D3327),
    bandExcellentTint: Color(0xFF16222E),
    bandExcellentLine: Color(0xFF2A3A4A),
    productBlueTint: Color(0xFF16222E),
    productOrangeTint: Color(0xFF2A211A),
    productGreenTint: Color(0xFF16241B),
    productIndigoTint: Color(0xFF252332),
    productRoseTint: Color(0xFF2A2130),
    productVioletTint: Color(0xFF2C2939),
    heroGradient: [Color(0xFFA9A3F0), Color(0xFF9A92E0), Color(0xFFE7A0CA)],
    onboardingWashes: [
      [Color(0xFF252332), Color(0xFF232130), Color(0xFF1D1B27)],
      [Color(0xFF2A2130), Color(0xFF2A2130), Color(0xFF1D1B27)],
      [Color(0xFF2C2939), Color(0xFF232130), Color(0xFF1D1B27)],
    ],
    dotInactiveWarm: Color(0xFF3A3040),
    shadowTone: Color(0xFF000000),
  );

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInset,
    Color? surfaceLow,
    Color? tint,
    Color? tintSoft,
    Color? tintPanel,
    Color? border,
    Color? borderSoft,
    Color? borderField,
    Color? divider,
    Color? dotInactive,
    Color? meterTrack,
    Color? ink,
    Color? inkSoft,
    Color? bodyStrong,
    Color? body,
    Color? muted,
    Color? placeholder,
    Color? faint,
    Color? fainter,
    Color? onTint,
    Color? action,
    Color? actionText,
    Color? start,
    Color? startText,
    Color? startLight,
    Color? success,
    Color? successText,
    Color? danger,
    Color? dangerText,
    Color? warning,
    Color? warningText,
    Color? critical,
    Color? info,
    Color? star,
    Color? onAccent,
    Color? appleMark,
    Color? bandCriticalTint,
    Color? bandCriticalLine,
    Color? bandNeedsTint,
    Color? bandNeedsLine,
    Color? bandGoodTint,
    Color? bandGoodLine,
    Color? bandExcellentTint,
    Color? bandExcellentLine,
    Color? productBlueTint,
    Color? productOrangeTint,
    Color? productGreenTint,
    Color? productIndigoTint,
    Color? productRoseTint,
    Color? productVioletTint,
    List<Color>? heroGradient,
    List<List<Color>>? onboardingWashes,
    Color? dotInactiveWarm,
    Color? shadowTone,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceInset: surfaceInset ?? this.surfaceInset,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      tint: tint ?? this.tint,
      tintSoft: tintSoft ?? this.tintSoft,
      tintPanel: tintPanel ?? this.tintPanel,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      borderField: borderField ?? this.borderField,
      divider: divider ?? this.divider,
      dotInactive: dotInactive ?? this.dotInactive,
      meterTrack: meterTrack ?? this.meterTrack,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      placeholder: placeholder ?? this.placeholder,
      faint: faint ?? this.faint,
      fainter: fainter ?? this.fainter,
      onTint: onTint ?? this.onTint,
      action: action ?? this.action,
      actionText: actionText ?? this.actionText,
      start: start ?? this.start,
      startText: startText ?? this.startText,
      startLight: startLight ?? this.startLight,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      danger: danger ?? this.danger,
      dangerText: dangerText ?? this.dangerText,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      critical: critical ?? this.critical,
      info: info ?? this.info,
      star: star ?? this.star,
      onAccent: onAccent ?? this.onAccent,
      appleMark: appleMark ?? this.appleMark,
      bandCriticalTint: bandCriticalTint ?? this.bandCriticalTint,
      bandCriticalLine: bandCriticalLine ?? this.bandCriticalLine,
      bandNeedsTint: bandNeedsTint ?? this.bandNeedsTint,
      bandNeedsLine: bandNeedsLine ?? this.bandNeedsLine,
      bandGoodTint: bandGoodTint ?? this.bandGoodTint,
      bandGoodLine: bandGoodLine ?? this.bandGoodLine,
      bandExcellentTint: bandExcellentTint ?? this.bandExcellentTint,
      bandExcellentLine: bandExcellentLine ?? this.bandExcellentLine,
      productBlueTint: productBlueTint ?? this.productBlueTint,
      productOrangeTint: productOrangeTint ?? this.productOrangeTint,
      productGreenTint: productGreenTint ?? this.productGreenTint,
      productIndigoTint: productIndigoTint ?? this.productIndigoTint,
      productRoseTint: productRoseTint ?? this.productRoseTint,
      productVioletTint: productVioletTint ?? this.productVioletTint,
      heroGradient: heroGradient ?? this.heroGradient,
      onboardingWashes: onboardingWashes ?? this.onboardingWashes,
      dotInactiveWarm: dotInactiveWarm ?? this.dotInactiveWarm,
      shadowTone: shadowTone ?? this.shadowTone,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceInset: c(surfaceInset, other.surfaceInset),
      surfaceLow: c(surfaceLow, other.surfaceLow),
      tint: c(tint, other.tint),
      tintSoft: c(tintSoft, other.tintSoft),
      tintPanel: c(tintPanel, other.tintPanel),
      border: c(border, other.border),
      borderSoft: c(borderSoft, other.borderSoft),
      borderField: c(borderField, other.borderField),
      divider: c(divider, other.divider),
      dotInactive: c(dotInactive, other.dotInactive),
      meterTrack: c(meterTrack, other.meterTrack),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      bodyStrong: c(bodyStrong, other.bodyStrong),
      body: c(body, other.body),
      muted: c(muted, other.muted),
      placeholder: c(placeholder, other.placeholder),
      faint: c(faint, other.faint),
      fainter: c(fainter, other.fainter),
      onTint: c(onTint, other.onTint),
      action: c(action, other.action),
      actionText: c(actionText, other.actionText),
      start: c(start, other.start),
      startText: c(startText, other.startText),
      startLight: c(startLight, other.startLight),
      success: c(success, other.success),
      successText: c(successText, other.successText),
      danger: c(danger, other.danger),
      dangerText: c(dangerText, other.dangerText),
      warning: c(warning, other.warning),
      warningText: c(warningText, other.warningText),
      critical: c(critical, other.critical),
      info: c(info, other.info),
      star: c(star, other.star),
      onAccent: c(onAccent, other.onAccent),
      appleMark: c(appleMark, other.appleMark),
      bandCriticalTint: c(bandCriticalTint, other.bandCriticalTint),
      bandCriticalLine: c(bandCriticalLine, other.bandCriticalLine),
      bandNeedsTint: c(bandNeedsTint, other.bandNeedsTint),
      bandNeedsLine: c(bandNeedsLine, other.bandNeedsLine),
      bandGoodTint: c(bandGoodTint, other.bandGoodTint),
      bandGoodLine: c(bandGoodLine, other.bandGoodLine),
      bandExcellentTint: c(bandExcellentTint, other.bandExcellentTint),
      bandExcellentLine: c(bandExcellentLine, other.bandExcellentLine),
      productBlueTint: c(productBlueTint, other.productBlueTint),
      productOrangeTint: c(productOrangeTint, other.productOrangeTint),
      productGreenTint: c(productGreenTint, other.productGreenTint),
      productIndigoTint: c(productIndigoTint, other.productIndigoTint),
      productRoseTint: c(productRoseTint, other.productRoseTint),
      productVioletTint: c(productVioletTint, other.productVioletTint),
      heroGradient: [
        for (var i = 0; i < heroGradient.length; i++)
          c(heroGradient[i], other.heroGradient[i]),
      ],
      onboardingWashes: [
        for (var i = 0; i < onboardingWashes.length; i++)
          [
            for (var j = 0; j < onboardingWashes[i].length; j++)
              c(onboardingWashes[i][j], other.onboardingWashes[i][j]),
          ],
      ],
      dotInactiveWarm: c(dotInactiveWarm, other.dotInactiveWarm),
      shadowTone: c(shadowTone, other.shadowTone),
    );
  }
}

/// Text styles bound to a palette.
///
/// Every named style carries its own colour, so it has to be resolved against
/// the active [AppColors] rather than held as a constant. Reach for these via
/// `context.t`; for one-off styles use [AppTheme.font], which takes an
/// explicit colour and needs no palette.
@immutable
class AppText {
  const AppText(this.c);

  final AppColors c;

  /// 30/800/-1.1 — onboarding and auth page titles.
  TextStyle get h1 => AppTheme.font(
      size: 30, weight: FontWeight.w800, color: c.ink, letterSpacing: -1.1);

  /// 29/800/-1 — welcome headline.
  TextStyle get h1Welcome => AppTheme.font(
      size: 29, weight: FontWeight.w800, color: c.ink, letterSpacing: -1);

  /// 24/800/-0.8 — in-flow screen titles (Cart, Checkout, Help).
  TextStyle get h2 => AppTheme.font(
      size: 24, weight: FontWeight.w800, color: c.ink, letterSpacing: -0.8);

  /// 22/800/-0.7 — compact screen titles beside a back button.
  TextStyle get h3 => AppTheme.font(
      size: 22, weight: FontWeight.w800, color: c.ink, letterSpacing: -0.7);

  /// 15/800 — card headings.
  TextStyle get cardTitle =>
      AppTheme.font(size: 15, weight: FontWeight.w800, color: c.ink);

  /// 15/1.55 — standard body copy.
  TextStyle get bodyText => AppTheme.font(size: 15, color: c.body, height: 1.55);

  /// 13.5/1.5 — dense body copy inside cards.
  TextStyle get bodySmall =>
      AppTheme.font(size: 13.5, color: c.bodyStrong, height: 1.5);

  /// 15/1.3 — the label side of an information row.
  ///
  /// Rows across the app were each spelling out 13.5 independently: the owner
  /// profile, the pet profile and the analytics card all had their own copy
  /// of the same row with the same literal in it. Three copies meant three
  /// places to drift, and 13.5 sat a full step under iOS's own secondary
  /// text size — which is why the detail screens read as a shrunken canvas
  /// rather than a native app. One token, at the platform's subheadline size.
  TextStyle get rowLabel =>
      AppTheme.font(size: 15, color: c.muted, height: 1.3);

  /// 15/700/1.3 — the value side of an information row. Same size as
  /// [rowLabel]; the weight carries the hierarchy, not the size.
  TextStyle get rowValue => AppTheme.font(
      size: 15, weight: FontWeight.w700, color: c.ink, height: 1.3);

  /// [rowValue] for a value the record does not have ("Not set").
  TextStyle get rowValueEmpty =>
      AppTheme.font(size: 15, weight: FontWeight.w700, color: c.muted, height: 1.3);

  /// 12.5/1.3 — the secondary line under a value.
  TextStyle get rowNote =>
      AppTheme.font(size: 12.5, color: c.muted, height: 1.3);

  /// 12/700/1.0 uppercase — section labels.
  TextStyle get overline => AppTheme.font(
      size: 12, weight: FontWeight.w700, color: c.muted, letterSpacing: 1);

  /// 17/700/-0.2 — primary CTA label.
  TextStyle get button => AppTheme.font(
      size: 17,
      weight: FontWeight.w700,
      color: c.onAccent,
      letterSpacing: -0.2);
}

/// Resolves the active palette and its type scale from the widget tree.
extension AppThemeContext on BuildContext {
  /// The active colour palette. `context.c.action`, `context.c.ink`, …
  AppColors get c =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  /// The type scale bound to the active palette. `context.t.h1`, …
  AppText get t => AppText(c);

  /// True while the dark palette is active.
  bool get isDark => c.brightness == Brightness.dark;
}

/// Appearance-independent tokens, the type factory, and the two [ThemeData]s.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Radii and metrics
  // ---------------------------------------------------------------------

  static const double radiusCta = 29;
  static const double radiusCard = 20;
  static const double radiusCardSmall = 18;
  static const double radiusField = 16;
  static const double radiusChip = 18;

  /// Primary CTA height (58 on auth screens, 56 in-flow).
  static const double ctaHeight = 58;
  static const double ctaHeightCompact = 56;
  static const double fieldHeight = 56;
  static const double fieldHeightCompact = 54;

  // ---------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------
  //
  // Manrope — the face mypetfit.in already uses, so the app matches the
  // brand rather than approximating it. Bundled, so it renders identically
  // on iOS and Android; every text style routes through [font].

  /// Manrope carries no emoji glyphs, so headings containing them (e.g. the
  /// 👋 on sign-in) fall through to the platform emoji font instead of tofu.
  static const List<String> _emojiFallback = [
    'Apple Color Emoji',
    'Noto Color Emoji',
    'Segoe UI Emoji',
  ];

  /// The bundled family name, matching pubspec.yaml.
  static const String fontFamily = 'Manrope';

  static TextStyle font({
    double? size,
    FontWeight? weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: _emojiFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ---------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------

  static ThemeData get light => _build(ThemeData.light(useMaterial3: true),
      AppColors.light, Brightness.light);

  static ThemeData get dark =>
      _build(ThemeData.dark(useMaterial3: true), AppColors.dark, Brightness.dark);

  static ThemeData _build(
    ThemeData base,
    AppColors c,
    Brightness brightness,
  ) {
    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.action,
        secondary: c.start,
        surface: c.surface,
        error: c.critical,
        onPrimary: c.onAccent,
        onSecondary: c.onAccent,
        onSurface: c.ink,
        onError: c.onAccent,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: _emojiFallback,
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.ink),
        titleTextStyle: AppText(c).h3,
      ),
      dividerTheme: DividerThemeData(
        color: c.borderSoft,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
