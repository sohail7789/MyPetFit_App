import 'package:flutter/material.dart';
import '../config/theme.dart';

/// The bordered rounded card that carries almost every content block in the
/// design: 1px hairline, 20px radius, white or lightly tinted fill.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.background = AppTheme.surface,
    this.borderColor,
    this.radius = AppTheme.radiusCard,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppTheme.border),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// The uppercase 12/700/1px section label that precedes grouped content
/// ("DELIVER TO", "PAYMENT", "COMMON QUESTIONS").
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTheme.overline);
  }
}
