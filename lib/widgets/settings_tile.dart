import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'info_row.dart';
import 'app_button.dart';

/// Back button + title header used by every account sub-screen.
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            semanticLabel: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.t.h2,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A grouped list of [SettingsTile]s inside one rounded bordered card.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: context.c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: context.c.borderSoft),
          ],
        ],
      ),
    );
  }
}

/// One navigable row: a tinted icon square, a label and a chevron.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Renders the row in the danger tone — used by "Delete account".
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint =
        destructive ? context.c.bandCriticalTint : context.c.surfaceRaised;
    final accent = destructive ? context.c.dangerText : context.c.actionText;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: AppTheme.font(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: destructive ? context.c.dangerText : context.c.ink,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.c.faint,
            ),
          ],
        ),
      ),
    );
  }
}

/// A row with a label, supporting hint and a toggle.
class SettingsSwitchTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Optional leading glyph. Supply one when the row sits in a
  /// [SettingsGroup] alongside [SettingsTile]s, so the icon column lines up
  /// instead of the toggle row starting flush left.
  final IconData? icon;

  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.c.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 17, color: context.c.actionText),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.font(
                      size: 14,
                      weight: FontWeight.w700,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: AppTheme.font(size: 12.5, color: context.c.body),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(value: value),
          ],
        ),
      ),
    );
  }
}

/// A settings row whose choice is a segmented control rather than a single
/// on/off — used where "follow the system" is a real third state and not
/// just the absence of a preference.
class SettingsSegmentedTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  const SettingsSegmentedTile({
    super.key,
    required this.icon,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTheme.font(
      size: 14.5,
      weight: FontWeight.w700,
      color: context.c.ink,
    );

    final leading = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.c.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 17, color: context.c.actionText),
    );

    final control = _Segmented<T>(
      options: options,
      value: value,
      onChanged: onChanged,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      // The control wants a fixed amount of room — three pills of copy — and
      // the label got whatever was left. On a 390pt phone that left about
      // 82pt for a word needing 88, so "Appearance" shed its last character
      // onto a second line: `Appearanc / e`. Shrinking either side would fix
      // the symptom by making something unreadable, so instead the row is
      // measured, and when the two genuinely cannot share a line the control
      // takes one of its own underneath. Nothing is scaled, clipped or
      // truncated, and the segmented control keeps its full width and every
      // one of its tap targets.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final labelWidth = InfoRow.widthOf(label, labelStyle, scaler);
          final controlWidth = _Segmented.widthOf<T>(context, options);

          final fits =
              36 + 13 + labelWidth + 12 + controlWidth <= constraints.maxWidth;

          if (!fits) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 13),
                    Expanded(child: Text(label, style: labelStyle)),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: control),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 13),
              Expanded(child: Text(label, style: labelStyle)),
              const SizedBox(width: 12),
              control,
            ],
          );
        },
      ),
    );
  }
}

/// The track itself: one pill per option, the selected one filled.
class _Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Horizontal padding inside one pill, and around the track.
  static const double _pillPadding = 11;
  static const double _trackPadding = 3;
  static const double _optionSize = 12.5;

  /// How much room the track needs for [options] at the current text scale.
  ///
  /// The control is the fixed side of the row — it is three words of copy and
  /// cannot give any width back — so the row has to know its width to decide
  /// whether the label can sit beside it.
  static double widthOf<T>(
    BuildContext context,
    List<(T, String)> options,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = AppTheme.font(size: _optionSize, weight: FontWeight.w700);

    var total = _trackPadding * 2;
    for (final (_, text) in options) {
      total += InfoRow.widthOf(text, style, scaler) + _pillPadding * 2;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_trackPadding),
      decoration: BoxDecoration(
        color: context.c.tint,
        borderRadius: BorderRadius.circular(11),
      ),
      // Wrap, not Row: at a larger text scale three pills of copy need more
      // width than the card has, and a Row simply overflows. Wrapping lets
      // the options fall onto a second line at their full size rather than
      // being clipped or shrunk.
      child: Wrap(
        spacing: 0,
        runSpacing: 4,
        children: [
          for (final (option, text) in options)
            GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: _pillPadding,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: option == value ? context.c.action : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: AppTheme.font(
                    size: _optionSize,
                    weight: FontWeight.w700,
                    color: option == value
                        ? context.c.onAccent
                        : context.c.body,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 44×26 pill switch from the design.
class AppSwitch extends StatelessWidget {
  final bool value;

  const AppSwitch({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: value ? context.c.action : context.c.dotInactive,
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: context.c.onAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.c.ink.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
