import 'package:flutter/material.dart';
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
  final double height;
  final double radius;

  /// Renders static text instead of an input — used for the consent date.
  final String? readOnlyValue;

  final Color background;

  const LabeledField({
    super.key,
    required this.label,
    this.labelNote,
    this.hint = '',
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.height = 58,
    this.radius = AppTheme.radiusField,
    this.readOnlyValue,
    this.background = AppTheme.surface,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTheme.font(
      size: 15,
      weight: FontWeight.w600,
      color: AppTheme.ink,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
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
                          color: AppTheme.body,
                        ),
                      ),
                    ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              size: 10,
              weight: FontWeight.w700,
              color: AppTheme.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          if (readOnlyValue != null)
            Text(readOnlyValue!, maxLines: 1, style: valueStyle)
          else
            SizedBox(
              height: 20,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onChanged: onChanged,
                cursorColor: AppTheme.action,
                style: valueStyle,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: valueStyle.copyWith(
                    color: AppTheme.placeholder,
                    fontWeight: FontWeight.w500,
                  ),
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
                  color: selected == option ? AppTheme.tint : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == option
                        ? AppTheme.action
                        : AppTheme.border,
                  ),
                ),
                child: Text(
                  option,
                  style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w700,
                    color: selected == option
                        ? AppTheme.action
                        : AppTheme.body,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
