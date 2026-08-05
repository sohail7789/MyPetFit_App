import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG markup copied verbatim from the design files, so icons render exactly
/// as drawn rather than being approximated with Material glyphs.
class AppIcons {
  AppIcons._();

  static String _stroke(String body, Color color, double width) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="${_hex(color)}" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">$body</svg>';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  // -- Form field icons -------------------------------------------------

  static String mail(Color c) => _stroke(
      '<rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M3 7.5l9 6 9-6"/>',
      c,
      1.9);

  static String lock(Color c) => _stroke(
      '<rect x="4" y="10.5" width="16" height="10.5" rx="3"/>'
      '<path d="M8 10.5V8a4 4 0 018 0v2.5"/>',
      c,
      1.9);

  static String person(Color c) => _stroke(
      '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.4 3.1-5.6 7-5.6s7 2.2 7 5.6"/>',
      c,
      1.9);

  static String username(Color c) => _stroke(
      '<path d="M4 20v-1.4C4 15.5 7.6 13 12 13s8 2.5 8 5.6V20"/>'
      '<circle cx="12" cy="7.5" r="3.8"/>',
      c,
      1.9);

  /// Eye with a strike-through — the "hide password" state.
  static String eyeOff(Color c) => _stroke(
      '<path d="M3 12s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6z"/>'
      '<circle cx="12" cy="12" r="2.6"/><path d="M4 20L20 4"/>',
      c,
      1.9);

  static String eye(Color c) => _stroke(
      '<path d="M3 12s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6z"/>'
      '<circle cx="12" cy="12" r="2.6"/>',
      c,
      1.9);

  // -- Navigation / chrome ----------------------------------------------

  static String back(Color c) =>
      _stroke('<path d="M14.5 5L8 12l6.5 7"/>', c, 2.6);

  static String chevronRight([Color c = Colors.white]) =>
      _stroke('<path d="M9 5l7 7-7 7"/>', c, 2.6);

  static String chevronDown(Color c) =>
      _stroke('<path d="M5 8l7 7 7-7"/>', c, 3);

  static String check([Color c = Colors.white, double w = 3.4]) =>
      _stroke('<path d="M5 12.5l4.5 4.5L19 7"/>', c, w);

  static String globe(Color c) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="${_hex(c)}" stroke-width="2"><circle cx="12" cy="12" r="9"/>'
      '<path d="M3 12h18M12 3c2.5 2.6 2.5 15.4 0 18M12 3c-2.5 2.6-2.5 15.4 0 18"/></svg>';

  /// Paper plane on the "Send Reset Link" CTA.
  static String send([Color c = Colors.white]) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="${_hex(c)}" stroke-width="2" stroke-linejoin="round">'
      '<path d="M21.5 2.5L2.8 9.9l6.6 2.6 2.6 6.6 9.5-16.6z"/>'
      '<path d="M9.4 12.5l4.6-4.6"/></svg>';

  /// Small heart watermark on the sign-in hero.
  static String heart(Color c, double opacity) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="${_hex(c)}" opacity="$opacity">'
      '<path d="M12 21S3 14.6 3 9.3C3 6.4 5.3 4 8.2 4 9.8 4 11.2 4.8 12 6c.8-1.2 '
      '2.2-2 3.8-2C18.7 4 21 6.4 21 9.3 21 14.6 12 21 12 21z"/></svg>';

  // -- Brand marks -------------------------------------------------------

  static const String google =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill="#4285F4" d="M23 12.2c0-.8-.1-1.6-.2-2.3H12v4.4h6.2a5.3 5.3 0 01-2.3 3.5v2.9h3.6c2.1-2 3.5-4.9 3.5-8.5z"/>'
      '<path fill="#34A853" d="M12 23.5c3.1 0 5.7-1 7.5-2.8l-3.6-2.9c-1 .7-2.3 1.1-3.9 1.1-3 0-5.6-2-6.5-4.8H1.8v3A11.5 11.5 0 0012 23.5z"/>'
      '<path fill="#FBBC05" d="M5.5 14.1a7 7 0 010-4.4v-3H1.8a11.5 11.5 0 000 10.4l3.7-3z"/>'
      '<path fill="#EA4335" d="M12 5c1.7 0 3.2.6 4.4 1.7l3.2-3.2A11.4 11.4 0 001.8 6.7l3.7 3C6.4 7 9 5 12 5z"/></svg>';

  /// Apple's mark is monochrome and must invert between appearances, so the
  /// colour is supplied rather than baked in.
  static String apple(Color c) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${_hex(c)}">'
      '<path d="M16.4 1.4c0 1.2-.5 2.2-1.3 3-.9.9-1.9 1.5-3 1.4-.1-1.1.4-2.3 1.2-3.1.8-.8 2.1-1.4 3.1-1.3zM20.5 17.1c-.5 1.3-.8 1.9-1.5 3-1 1.5-2.4 3.4-4.1 3.5-1.6 0-2-1-4-1-2.1 0-2.5 1-4.1 1-1.7 0-3.1-1.8-4.1-3.3-2.7-4.2-3-9.1-1.3-11.7 1.2-1.8 3.1-2.9 4.9-2.9 1.9 0 3.1 1 4.7 1 1.5 0 2.4-1 4.6-1 1.7 0 3.5.9 4.8 2.5-4.2 2.3-3.5 8.3.1 9.9z"/></svg>';
}

/// Renders one of [AppIcons]' SVG strings at a given size.
class AppIcon extends StatelessWidget {
  final String svg;
  final double size;

  const AppIcon(this.svg, {super.key, required this.size});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        svg,
        width: size,
        height: size,
      );
}
