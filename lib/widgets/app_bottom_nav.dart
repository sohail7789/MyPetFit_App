import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// The four shell tabs in the redesign.
enum AppTab { home, report, shop, account }

/// Bottom navigation from the design: a hairline-topped white bar where the
/// active tab becomes a tinted pill with an icon *and* label, while inactive
/// tabs show the icon alone.
class AppBottomNav extends StatelessWidget {
  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  static const _tabs = <AppTab, ({IconData icon, String label})>{
    AppTab.home: (icon: Icons.home_outlined, label: 'Home'),
    AppTab.report: (icon: Icons.description_outlined, label: 'Report'),
    AppTab.shop: (icon: Icons.shopping_cart_outlined, label: 'Shop'),
    AppTab.account: (icon: Icons.person_outline, label: 'Account'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final entry in _tabs.entries)
                _NavItem(
                  icon: entry.value.icon,
                  label: entry.value.label,
                  active: entry.key == current,
                  onTap: () {
                    if (entry.key == current) return;
                    HapticFeedback.selectionClick();
                    onSelect(entry.key);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: active ? AppTheme.action : AppTheme.muted,
              ),
              // Only the active tab carries a label, per the design.
              if (active) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: AppTheme.font(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: AppTheme.action,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
