import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// The app's canonical filled action button.
///
/// Deliberately reads as iOS-native: filled brand color, generous rounded
/// rect, tight labelLarge text, and a subtle scale/dim on press
/// (the "haptic-feeling" that Apple buttons have and Material buttons don't).
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// If provided, painted as a leading icon inside the button.
  final IconData? icon;

  /// Override the fill color. Defaults to `AppTheme.primary`.
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool v) {
    if (_disabled) return;
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    if (_disabled) return;
    // Light selection click on tap — matches native iOS button feel.
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? AppTheme.primary;
    final fg = Colors.white;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: _disabled ? null : _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _disabled
                ? bg.withValues(alpha: 0.35)
                : (_pressed ? bg.withValues(alpha: 0.88) : bg),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
