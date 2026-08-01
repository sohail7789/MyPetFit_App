import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the MyPetFit redesign.
///
/// Values are transcribed from the approved application design
/// (MyPetFit All Screens.dc.html and the four component files it imports).
/// The design is light-only; there is no dark variant yet.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Palette
  // ---------------------------------------------------------------------

  /// Primary action colour — buttons, active nav, selected states.
  static const Color action = Color(0xFF46437F);

  /// Secondary "start" colour — sign-up, place-order, celebratory CTAs.
  static const Color start = Color(0xFF8E4F7C);

  /// Lighter plum used for onboarding accents and password strength.
  static const Color startLight = Color(0xFFA76A96);

  /// Headings and high-emphasis text.
  static const Color ink = Color(0xFF2A2C5A);

  /// Body copy.
  static const Color body = Color(0xFF6B6D8F);

  /// Denser body copy inside cards.
  static const Color bodyStrong = Color(0xFF4A4A72);

  /// Muted meta text, uppercase section labels.
  static const Color muted = Color(0xFF8A8AA6);

  /// Input placeholders and inactive marks.
  static const Color placeholder = Color(0xFF9B9BB4);

  /// Screen background behind the app surface.
  static const Color canvas = Color(0xFFF1F0F6);

  /// Card / sheet surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Filled tint for selected chips, secondary buttons, active nav pill.
  static const Color tint = Color(0xFFEFECF5);

  /// Subtle tinted surface for pressed states and inset panels.
  static const Color tintSoft = Color(0xFFF7F5FA);

  /// Very light tinted panel used on checkout / detail cards.
  static const Color tintPanel = Color(0xFFF8F7FB);

  /// Standard hairline border.
  static const Color border = Color(0xFFE6E4EF);

  /// Lighter hairline used for footers and dividers between rows.
  static const Color borderSoft = Color(0xFFF0EEF6);

  /// Divider used for the "or continue with" rules.
  static const Color divider = Color(0xFFEAE8F1);

  /// Inactive pagination dot / toggle track.
  static const Color dotInactive = Color(0xFFD8D5E6);

  // Semantic accents ----------------------------------------------------

  static const Color success = Color(0xFF2E7D46);
  static const Color danger = Color(0xFFB0475A);
  static const Color critical = Color(0xFFC62828);
  static const Color warning = Color(0xFFC25A20);
  static const Color info = Color(0xFF1E6FA8);
  static const Color star = Color(0xFFC9A227);

  // ---------------------------------------------------------------------
  // Score bands — mirrors BANDS in MyPetFit Assessment.dc.html
  // ---------------------------------------------------------------------

  static const Color bandCriticalTint = Color(0xFFFBF0F0);
  static const Color bandCriticalLine = Color(0xFFF0D6D6);
  static const Color bandNeedsTint = Color(0xFFFDF4EE);
  static const Color bandNeedsLine = Color(0xFFF2E0D2);
  static const Color bandGoodTint = Color(0xFFF1F8F3);
  static const Color bandGoodLine = Color(0xFFD9EADF);
  static const Color bandExcellentTint = Color(0xFFEFF5FB);
  static const Color bandExcellentLine = Color(0xFFD5E4F1);

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
  // Elevation
  // ---------------------------------------------------------------------

  /// Glow under the primary (action) CTA.
  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: action.withValues(alpha: 0.42),
          blurRadius: 26,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Glow under the secondary (start) CTA.
  static List<BoxShadow> get ctaShadowStart => [
        BoxShadow(
          color: start.withValues(alpha: 0.42),
          blurRadius: 26,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
      ];

  /// Soft lift under text fields.
  static List<BoxShadow> get fieldShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.12),
          blurRadius: 6,
          spreadRadius: -4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Lift under floating circular back buttons.
  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: -8,
          offset: const Offset(0, 6),
        ),
      ];

  // ---------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------
  //
  // The design specifies SF Pro Display / SF Pro Text. Inter is the closest
  // freely-licensed match and renders identically across iOS and Android,
  // so every text style routes through [font].

  /// Inter carries no emoji glyphs, so headings containing them (e.g. the
  /// 👋 on sign-in) fall through to the platform emoji font instead of tofu.
  static const List<String> _emojiFallback = [
    'Apple Color Emoji',
    'Noto Color Emoji',
    'Segoe UI Emoji',
  ];

  static TextStyle font({
    double? size,
    FontWeight? weight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      ).copyWith(fontFamilyFallback: _emojiFallback);

  /// 30/800/-1.1 — onboarding and auth page titles.
  static TextStyle get h1 =>
      font(size: 30, weight: FontWeight.w800, color: ink, letterSpacing: -1.1);

  /// 29/800/-1 — welcome headline.
  static TextStyle get h1Welcome =>
      font(size: 29, weight: FontWeight.w800, color: ink, letterSpacing: -1);

  /// 24/800/-0.8 — in-flow screen titles (Cart, Checkout, Help).
  static TextStyle get h2 =>
      font(size: 24, weight: FontWeight.w800, color: ink, letterSpacing: -0.8);

  /// 22/800/-0.7 — compact screen titles beside a back button.
  static TextStyle get h3 =>
      font(size: 22, weight: FontWeight.w800, color: ink, letterSpacing: -0.7);

  /// 15/800 — card headings.
  static TextStyle get cardTitle =>
      font(size: 15, weight: FontWeight.w800, color: ink);

  /// 15/1.55 — standard body copy.
  static TextStyle get bodyText => font(size: 15, color: body, height: 1.55);

  /// 13.5/1.5 — dense body copy inside cards.
  static TextStyle get bodySmall =>
      font(size: 13.5, color: bodyStrong, height: 1.5);

  /// 12/700/1.0 uppercase — section labels.
  static TextStyle get overline => font(
        size: 12,
        weight: FontWeight.w700,
        color: muted,
        letterSpacing: 1,
      );

  /// 17/700/-0.2 — primary CTA label.
  static TextStyle get button => font(
        size: 17,
        weight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.2,
      );

  // ---------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      canvasColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: action,
        secondary: start,
        surface: surface,
        error: critical,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ink,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: h3,
      ),
      dividerTheme: const DividerThemeData(
        color: borderSoft,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
