import 'package:flutter/material.dart';
import '../config/theme.dart';

/// The rounded text field from the design: hairline border, soft lift, a
/// leading stroke icon, and a focus state that switches the border to the
/// action colour and adds a 3px translucent ring.
class AppField extends StatefulWidget {
  final String hint;

  /// Leading glyph — pass an [AppIcon] built from [AppIcons] so the field
  /// carries the design's own stroke artwork.
  final Widget? icon;

  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final double height;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  /// Trailing widget — the eye toggle on password fields.
  final Widget? trailing;

  final bool enabled;

  const AppField({
    super.key,
    required this.hint,
    this.icon,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.height = AppTheme.fieldHeight,
    this.onChanged,
    this.initialValue,
    this.trailing,
    this.enabled = true,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late final FocusNode _focus;
  TextEditingController? _internal;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_internal ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        if (_focus.hasFocus != _focused) {
          setState(() => _focused = _focus.hasFocus);
        }
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      // A floor, not a fixed height — see [LabeledField] for why. The row
      // still centres at the design's 56px when the font scale is 1.0.
      constraints: BoxConstraints(minHeight: widget.height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(
          color: _focused ? context.c.actionText : context.c.border,
        ),
        boxShadow: _focused
            // The design's focus ring: 0 0 0 3px rgba(70,67,127,.1).
            ? [
                BoxShadow(
                  color: context.c.action.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : context.c.fieldShadow,
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              cursorColor: context.c.actionText,
              style: AppTheme.font(
                size: 15,
                weight: FontWeight.w500,
                color: context.c.ink,
                height: 1.3,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                // Long placeholders ("+91 00000 00000") must ellipsize, not
                // wrap and drag the field's height with them.
                hintMaxLines: 1,
                hintStyle: AppTheme.font(
                  size: 15,
                  weight: FontWeight.w500,
                  color: context.c.placeholder,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
