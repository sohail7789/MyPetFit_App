import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Renders the official MyPetFit brand logo.
///
/// Uses the actual PNG asset (`assets/images/logo/mypetfit_logo.png`)
/// for the paw-heart icon. The wordmark is rendered as styled text:
/// "MyPet" in deep navy (#222853), "Fit" in mauve (#BF8CAC).
/// Tagline: "Intelligent Care for Lifelong Pet Health".
class MyPetFitLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool showPaws;
  final bool showIcon;
  final Color? taglineColor;

  static const String _logoAsset = 'assets/images/logo/mypetfit_logo.png';

  const MyPetFitLogo({
    super.key,
    this.fontSize = 36,
    this.showTagline = false,
    this.showPaws = false,
    this.showIcon = false,
    this.taglineColor,
  });

  /// Compact variant — small wordmark only, no icon.
  const MyPetFitLogo.compact({super.key, this.fontSize = 24})
      : showTagline = false,
        showPaws = false,
        showIcon = false,
        taglineColor = null;

  /// Full variant — logo icon + wordmark + tagline (welcome/splash screen).
  const MyPetFitLogo.full({super.key, this.fontSize = 44, this.taglineColor})
      : showTagline = true,
        showPaws = true,
        showIcon = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The brand navy is nearly invisible on the dark background, so the
    // "MyPet" half switches to white in dark mode. "Fit" keeps the mauve,
    // which carries enough contrast against both backgrounds.
    final navy = isDark ? Colors.white : AppTheme.primary;
    const mauve = AppTheme.secondary;

    final wordmark = RichText(
      text: TextSpan(
        children: [
          for (final (letter, color) in [
            ('M', navy), ('y', navy),
            ('P', navy), ('e', navy), ('t', navy),
            ('F', mauve), ('i', mauve), ('t', mauve),
          ])
            TextSpan(
              text: letter,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
        ],
      ),
    );

    final taglineStyle = GoogleFonts.inter(
      fontSize: fontSize * 0.28,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      color: taglineColor ?? AppTheme.mutedText(isDark),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Official logo PNG
        if (showIcon) ...[
          Image.asset(
            _logoAsset,
            width: fontSize * 3.0,
            height: fontSize * 3.0,
            fit: BoxFit.contain,
          ),
          SizedBox(height: fontSize * 0.1),
        ],
        wordmark,
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Intelligent Care for Lifelong Pet Health',
            style: taglineStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (showPaws && !showIcon) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets,
                  size: fontSize * 0.28, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Icon(Icons.pets,
                  size: fontSize * 0.22, color: AppTheme.secondary),
              const SizedBox(width: 4),
              Icon(Icons.pets,
                  size: fontSize * 0.18, color: AppTheme.secondary),
            ],
          ),
        ],
      ],
    );
  }
}
