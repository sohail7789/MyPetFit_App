import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Button variants used across the redesign.
enum AppButtonVariant {
  /// Filled #46437F pill — the default primary action.
  action,

  /// Filled #8E4F7C pill — sign-up, place-order, celebratory actions.
  start,

  /// White pill with a hairline border — "Continue shopping", "Back to shop".
  outline,

  /// Filled #EFECF5 pill with #46437F label — "In cart", secondary states.
  tinted,

  /// Filled #B0475A pill — destructive actions ("Delete my account") and the
  /// vet-alert call to action.
  danger,
}

/// The pill CTA from the design.
///
/// Matches the design's press affordance (`transform: scale(.98)`) and its
/// disabled treatment, where a blocked primary drops to the inactive tint.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;

  /// Optional leading icon, e.g. the paper-plane on "Send Reset Link".
  final Widget? icon;

  /// Full-bleed by default; pass false for intrinsic-width buttons.
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.action,
    this.height = AppTheme.ctaHeight,
    this.icon,
    this.expand = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  Color get _background {
    if (!_enabled) return AppTheme.dotInactive;
    switch (widget.variant) {
      case AppButtonVariant.action:
        return AppTheme.action;
      case AppButtonVariant.start:
        return AppTheme.start;
      case AppButtonVariant.outline:
        return AppTheme.surface;
      case AppButtonVariant.tinted:
        return AppTheme.tint;
      case AppButtonVariant.danger:
        return AppTheme.danger;
    }
  }

  Color get _foreground {
    if (!_enabled) return Colors.white;
    switch (widget.variant) {
      case AppButtonVariant.action:
      case AppButtonVariant.start:
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.outline:
      case AppButtonVariant.tinted:
        return AppTheme.action;
    }
  }

  List<BoxShadow>? get _shadow {
    if (!_enabled || _pressed) return null;
    switch (widget.variant) {
      case AppButtonVariant.action:
        return AppTheme.ctaShadow;
      case AppButtonVariant.start:
        return AppTheme.ctaShadowStart;
      case AppButtonVariant.danger:
        return [
          BoxShadow(
            color: AppTheme.danger.withValues(alpha: 0.4),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ];
      case AppButtonVariant.outline:
      case AppButtonVariant.tinted:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // A pill at every height. Using height/2 turned into a rounded rectangle
    // once the button grew past its resting size at larger font scales;
    // an oversized radius is clamped back to a stadium by RRect.
    const radius = 999.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            // Two lines before ellipsizing: labels like "Place order ·
            // ₹2,298" and "Start the assessment" stop fitting on one line at
            // a large font scale, and a truncated price is worse than a
            // taller button.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.button.copyWith(
              color: _foreground,
              fontSize: widget.variant == AppButtonVariant.outline ? 15 : 17,
              height: 1.2,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // Minimum, not fixed — a two-line label at a large font scale has
          // to be able to make the button taller rather than be cut off.
          constraints: BoxConstraints(minHeight: widget.height),
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: widget.expand ? 16 : 22,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(radius),
            border: widget.variant == AppButtonVariant.outline
                ? Border.all(color: AppTheme.border)
                : null,
            boxShadow: _shadow,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

/// The 42/44px circular icon button used for "Back" and header actions.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color background;
  final Color foreground;

  /// Floating variant (white + drop shadow) used over artwork.
  final bool floating;

  final String? semanticLabel;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 42,
    this.background = AppTheme.tintSoft,
    this.foreground = AppTheme.ink,
    this.floating = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: floating ? AppTheme.surface : background,
            shape: BoxShape.circle,
            boxShadow: floating ? AppTheme.floatShadow : null,
          ),
          child: Icon(icon, size: size * 0.45, color: foreground),
        ),
      ),
    );
  }
}
