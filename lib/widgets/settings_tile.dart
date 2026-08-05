import 'package:flutter/material.dart';
import '../config/theme.dart';
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

  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
