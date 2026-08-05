import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// The stacked form field used across the assessment: a small uppercase
/// caption sitting above the value, inside a hairline rounded box.
///
/// Distinct from [AppField], which is the icon-and-placeholder style used on
/// the auth screens.
class LabeledField extends StatelessWidget {
  final String label;

  /// Rendered in normal case after [label], e.g. "optional".
  final String? labelNote;

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  /// Input restrictions, e.g. digits-only and a length cap on a PIN code.
  final List<TextInputFormatter>? inputFormatters;

  /// The box's resting height. It is a *minimum*, not a fixed size: the box
  /// grows when the platform font scale does. Pinning it caused the value
  /// row to be sliced in half on devices with a larger display size set.
  final double height;

  final double radius;

  /// Renders static text instead of an input — used for the consent date.
  final String? readOnlyValue;

  /// Defaults to the card surface for the active appearance.
  final Color? background;

  const LabeledField({
    super.key,
    required this.label,
    this.labelNote,
    this.hint = '',
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.inputFormatters,
    this.height = 58,
    this.radius = AppTheme.radiusField,
    this.readOnlyValue,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTheme.font(
      size: 15,
      weight: FontWeight.w600,
      color: context.c.ink,
      // Manrope's descenders sit low; an explicit leading gives the value row
      // a stable line box instead of one that varies with the glyphs typed.
      height: 1.3,
    );

    // The box is padded rather than pinned, so its height is whatever the
    // caption plus the value actually need at the current font scale. The
    // caller's [height] only sets the floor, which keeps the design's
    // resting proportions at scale 1.0.
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: background ?? context.c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.c.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: label.toUpperCase(),
              children: labelNote == null
                  ? null
                  : [
                      TextSpan(
                        text: ' $labelNote',
                        style: AppTheme.font(
                          size: 10,
                          weight: FontWeight.w700,
                          color: context.c.body,
                        ),
                      ),
                    ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              size: 10,
              weight: FontWeight.w700,
              color: context.c.muted,
              letterSpacing: 0.8,
              // Captions are all-caps and single line; a tight leading keeps
              // the two-row stack compact without risking a clipped cap.
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          if (readOnlyValue != null)
            Text(
              readOnlyValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            )
          else
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              cursorColor: context.c.actionText,
              style: valueStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                // Without this the field reserves 24px for a helper/error
                // line that never renders, which pushed the value down
                // behind the box's bottom edge.
                isCollapsed: false,
                hintText: hint,
                hintMaxLines: 1,
                hintStyle: valueStyle.copyWith(
                  color: context.c.placeholder,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The pill selector used for Gender on the pet-details screen.
class ChoiceChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == option ? context.c.tint : context.c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == option
                        ? context.c.actionText
                        : context.c.border,
                  ),
                ),
                child: Text(
                  option,
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w700,
                    color: selected == option
                        ? context.c.actionText
                        : context.c.body,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
