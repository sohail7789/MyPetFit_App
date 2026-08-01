import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'app_icons.dart';

/// "or continue with" rule — a hairline either side of centred caption text.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: AppTheme.font(size: 13, color: AppTheme.muted),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.divider)),
      ],
    );
  }
}

/// One of the bordered white social buttons (Google / Apple).
class SocialButton extends StatelessWidget {
  final String label;
  final String svg;
  final double iconSize;
  final double height;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.svg,
    this.iconSize = 19,
    this.height = 54,
    this.onPressed,
  });

  const SocialButton.google({
    super.key,
    this.height = 54,
    this.iconSize = 19,
    this.onPressed,
  })  : label = 'Google',
        svg = AppIcons.google;

  const SocialButton.apple({
    super.key,
    this.height = 54,
    this.iconSize = 18,
    this.onPressed,
  })  : label = 'Apple',
        svg = AppIcons.apple;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(svg, size: iconSize),
            const SizedBox(width: 9),
            Text(
              label,
              style: AppTheme.font(
                size: 15,
                weight: FontWeight.w600,
                color: const Color(0xFF33345E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Google + Apple pair, side by side.
class SocialRow extends StatelessWidget {
  final double height;
  final double? maxWidth;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  const SocialRow({
    super.key,
    this.height = 54,
    this.maxWidth,
    this.onGoogle,
    this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: SocialButton.google(height: height, onPressed: onGoogle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SocialButton.apple(height: height, onPressed: onApple),
        ),
      ],
    );

    if (maxWidth == null) return row;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: row,
    );
  }
}

/// "Already have an account? Log in" — caption plus an inline action.
class InlineLink extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;
  final TextAlign align;

  const InlineLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: prefix.isEmpty ? null : '$prefix ',
        style: AppTheme.font(size: 14, color: AppTheme.body),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: AppTheme.font(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.action,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: align,
    );
  }
}
