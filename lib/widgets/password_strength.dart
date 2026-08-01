import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Three-segment password strength meter with a trailing caption, as shown on
/// the sign-up and reset-password screens.
class PasswordStrength extends StatelessWidget {
  /// Filled segments, 0–3.
  final int level;

  final String label;

  /// Fill colour for completed segments.
  final Color color;

  /// Colour of the unfilled remainder.
  final Color track;

  const PasswordStrength({
    super.key,
    required this.level,
    required this.label,
    this.color = AppTheme.startLight,
    this.track = const Color(0xFFE4E1EE),
  });

  /// Derives the meter from a password, matching the design's stated rule
  /// of "8+ chars, 1 number".
  factory PasswordStrength.of(String password) {
    final long = password.length >= 8;
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasVariety = password.contains(RegExp(r'[^A-Za-z0-9]')) ||
        (password.contains(RegExp(r'[a-z]')) &&
            password.contains(RegExp(r'[A-Z]')));

    final level = [long, hasDigit, hasVariety].where((x) => x).length;
    final strong = level == 3;

    return PasswordStrength(
      level: password.isEmpty ? 0 : level,
      label: strong ? 'Strong' : '8+ chars, 1 number',
      color: strong ? AppTheme.start : AppTheme.startLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 5,
                decoration: BoxDecoration(
                  color: i < level ? color : track,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTheme.font(
              size: 12,
              weight: FontWeight.w700,
              color: AppTheme.start,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
