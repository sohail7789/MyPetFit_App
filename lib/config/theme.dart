import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme, tuned to feel like a native Apple app:
///   * Inter as an SF-Pro-adjacent typeface (Google Fonts' closest match).
///   * Tight negative letter-spacing on display sizes — the hallmark of
///     SF Pro Display and what separates "Material" from "iOS" typography.
///   * Very soft surfaces (system-background-style off-white in light,
///     tighter near-black with a blue-gray tint in dark).
///   * Cards with no visible shadow — just a hairline border. Elevation
///     is signaled through contrast, not drop-shadows.
///   * 14 pt corner radius (Apple's canonical rounded-rect).
class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // Brand palette (April 2026 brand guideline) — unchanged.
  // ─────────────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF222853); // deep navy
  static const Color secondary = Color(0xFFBF8CAC); // mauve / dusty rose
  static const Color accentBlue = Color(0xFF88A8D0);
  static const Color accentPink = Color(0xFFE0C8D5);
  static const Color neutralDark = Color(0xFF27415D);
  static const Color neutralDeep = Color(0xFF101F2F);

  // Logo wordmark colors
  static const Color logoNavy = primary;
  static const Color logoMauve = secondary;

  // Backwards-compat aliases (existing code references these)
  static const Color brandBlue = primary;
  static const Color brandGreen = Color(0xFF34A853);
  static const Color brandRed = Color(0xFFEA4335);
  static const Color brandYellow = Color(0xFFFBBC04);
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color accentColor = accentBlue;
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;

  static const List<Color> brandAccents = [
    primary,
    secondary,
    accentBlue,
    neutralDark,
  ];

  // Soft pastels (used for hero/category backgrounds — refined slightly)
  static const Color lightGreen = Color(0xFFE8F5EE);
  static const Color lightAzure = Color(0xFFEAF1F9);
  static const Color softPeach = Color(0xFFF6E9F0);
  static const Color softLavender = Color(0xFFEAD9E3);

  static const List<Color> categoryPastels = [
    lightAzure,
    softPeach,
    lightGreen,
    softLavender,
    lightAzure,
    softPeach,
    lightGreen,
    softLavender,
    lightAzure,
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // System neutrals — chosen to read as "iOS light / dark mode"
  // ─────────────────────────────────────────────────────────────────────────
  static const Color _lightScaffold = Color(0xFFF7F7F9);
  static const Color _lightInputFill = Color(0xFFF1F1F4);
  static const Color _lightHairline = Color(0xFFE5E5EA);
  static const Color _lightMuted = Color(0xFF8A8A8E);

  static const Color darkBlueBg = Color(0xFF0E1220); // tighter near-black
  static const Color darkBlueSurface = Color(0xFF1B2032);
  static const Color _darkHairline = Color(0xFF2A3143);
  static const Color darkBlueTextLight = Color(0xFFB6BAD1);

  // ─────────────────────────────────────────────────────────────────────────
  // Text
  // ─────────────────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF11131A);
  static const Color textLight = _lightMuted;

  // Status
  static const Color successColor = Color(0xFF34C759); // iOS system green
  static const Color warningColor = Color(0xFFFF9F0A); // iOS system orange
  static const Color errorColor = Color(0xFFFF3B30); // iOS system red

  // Gradients (kept for backwards compat)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightAzure, softPeach],
  );
  static const LinearGradient onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, lightAzure],
  );
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neutralDeep, neutralDark],
  );

  // Corner radii — 14 is Apple's canonical modal/card radius, 10 for buttons.
  static const double radiusCard = 18;
  static const double radiusInput = 14;
  static const double radiusButton = 14;

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic color helpers — one source of truth for "what color is a card /
  // hairline / muted label in this brightness". Screens should call these
  // instead of hand-picking pastels per-widget, which is how dark-mode
  // regressions crept in.
  // ─────────────────────────────────────────────────────────────────────────
  static Color surface(bool isDark) => isDark ? darkBlueSurface : Colors.white;
  static Color hairline(bool isDark) => isDark ? _darkHairline : _lightHairline;
  static Color mutedText(bool isDark) => isDark ? darkBlueTextLight : textLight;
  static Color heading(bool isDark) => isDark ? Colors.white : textDark;

  /// A tinted fill that stays readable in both modes: pastel in light,
  /// low-alpha accent wash in dark.
  static Color tint(bool isDark, Color accent, Color pastel) =>
      isDark ? accent.withValues(alpha: 0.16) : pastel;

  /// Color for interactive text and icons (links, inline actions).
  /// The brand navy sits at roughly 1.3:1 against the dark background —
  /// unreadable — so dark mode uses the light blue accent instead.
  static Color interactive(bool isDark) => isDark ? accentBlue : primary;

  // ─────────────────────────────────────────────────────────────────────────
  // Public text-theme builder — screens that need one-off styles can call
  // AppTheme.font(...) instead of GoogleFonts.inter(...) directly, so if
  // we ever swap the family (SF Pro on iOS, e.g.) it changes in one place.
  // ─────────────────────────────────────────────────────────────────────────
  static TextStyle font({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? _defaultTracking(fontSize),
        height: height,
      );

  /// SF-Pro-inspired negative tracking: larger sizes get tighter kerning.
  /// This is the single change that most makes text feel "iOS-native".
  static double _defaultTracking(double size) {
    if (size >= 30) return -0.6;
    if (size >= 24) return -0.4;
    if (size >= 20) return -0.3;
    if (size >= 17) return -0.2;
    if (size >= 15) return -0.1;
    return 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Light / dark theme entry points
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: accentBlue,
      error: errorColor,
      surface: Colors.white,
    );
    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: _lightScaffold,
      cardBg: Colors.white,
      textColor: textDark,
      mutedTextColor: _lightMuted,
      inputFill: _lightInputFill,
      hairline: _lightHairline,
      brightness: Brightness.light,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: accentBlue,
      secondary: secondary,
      tertiary: accentPink,
      error: errorColor,
      surface: darkBlueSurface,
    );
    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: darkBlueBg,
      cardBg: darkBlueSurface,
      textColor: Colors.white,
      mutedTextColor: darkBlueTextLight,
      inputFill: darkBlueSurface,
      hairline: _darkHairline,
      brightness: Brightness.dark,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared theme builder
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardBg,
    required Color textColor,
    required Color mutedTextColor,
    required Color inputFill,
    required Color hairline,
    required Brightness brightness,
  }) {
    // Type scale — sizes and weights modelled on the iOS Human Interface
    // Guidelines' "Large" text style set. The negative letter-spacing on
    // larger sizes is what separates SF Pro Display from Text on iOS.
    TextStyle t({
      required double size,
      required FontWeight weight,
      double? tracking,
      double? height,
      Color? color,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking ?? _defaultTracking(size),
          height: height,
          color: color ?? textColor,
        );

    final textTheme = TextTheme(
      displayLarge: t(size: 34, weight: FontWeight.w700, height: 1.15),
      displayMedium: t(size: 30, weight: FontWeight.w700, height: 1.18),
      displaySmall: t(size: 26, weight: FontWeight.w700, height: 1.2),
      headlineLarge: t(size: 24, weight: FontWeight.w700, height: 1.22),
      headlineMedium: t(size: 22, weight: FontWeight.w700, height: 1.25),
      headlineSmall: t(size: 20, weight: FontWeight.w600, height: 1.28),
      titleLarge: t(size: 20, weight: FontWeight.w600, height: 1.3),
      titleMedium: t(size: 17, weight: FontWeight.w600, height: 1.35),
      titleSmall: t(size: 15, weight: FontWeight.w600, height: 1.4),
      bodyLarge: t(size: 17, weight: FontWeight.w400, height: 1.45),
      bodyMedium: t(size: 15, weight: FontWeight.w400, height: 1.5),
      bodySmall: t(
        size: 13,
        weight: FontWeight.w400,
        height: 1.45,
        color: mutedTextColor,
      ),
      labelLarge: t(size: 15, weight: FontWeight.w600, tracking: -0.1),
      labelMedium: t(size: 13, weight: FontWeight.w600, tracking: 0),
      labelSmall: t(size: 12, weight: FontWeight.w600, tracking: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 0.5,
        space: 0.5,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false, // iOS-style left-aligned titles
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              brightness == Brightness.dark ? const Color(0xFF2A3143) : const Color(0xFFE5E5EA),
          disabledForegroundColor:
              brightness == Brightness.dark ? const Color(0xFF6B7080) : const Color(0xFF9A9AA0),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          side: BorderSide(color: hairline, width: 1),
          foregroundColor: textColor,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        // No drop shadow — iOS cards are defined by hairline borders and
        // subtle contrast, not elevation.
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: hairline, width: 0.5),
        ),
        color: cardBg,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle:
            GoogleFonts.inter(color: mutedTextColor, letterSpacing: -0.1),
        hintStyle: GoogleFonts.inter(
          color: mutedTextColor,
          fontSize: 15,
          letterSpacing: -0.1,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: errorColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: mutedTextColor,
        suffixIconColor: mutedTextColor,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            brightness == Brightness.dark ? Colors.white : textDark,
        contentTextStyle: GoogleFonts.inter(
          color: brightness == Brightness.dark ? textDark : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: primary,
        disabledColor: inputFill,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.05,
          color: textColor,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: hairline, width: 1.5),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: mutedTextColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textColor,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: mutedTextColor,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: hairline,
        circularTrackColor: hairline,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Design tokens — every screen composes from these instead of ad-hoc values.
// ───────────────────────────────────────────────────────────────────────────

/// 8-pt spacing scale. If a gap isn't one of these, it's off-system.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard screen edge inset.
  static const double page = 20;

  /// Vertical rhythm between content sections.
  static const double section = 24;
}

/// Corner-radius scale. sm=chips/controls, md=buttons/inputs, lg=cards,
/// xl=sheets/modals.
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

/// Motion tokens — premium apps use few, consistent durations.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration gentle = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}
