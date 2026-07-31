import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../account/account_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../wellness/wellness_hub_screen.dart';

/// Root shell with animated bottom navigation bar (Home / Health / Account).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  static const _tabs = <_TabDef>[
    _TabDef(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    _TabDef(icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, label: 'Health'),
    _TabDef(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Account'),
  ];

  static const _screens = <Widget>[
    HomeDashboardScreen(),
    WellnessHubScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AnimatedBottomBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        isDark: isDark,
        onTap: (i) {
          if (i == _currentIndex) return;
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabDef({required this.icon, required this.activeIcon, required this.label});
}

class _AnimatedBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabDef> tabs;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _AnimatedBottomBar({
    required this.currentIndex,
    required this.tabs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkBlueSurface : Colors.white;
    final tabWidth = MediaQuery.of(context).size.width / tabs.length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated sliding indicator bar
            SizedBox(
              height: 3,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * currentIndex + tabWidth * 0.2,
                    width: tabWidth * 0.6,
                    top: 0,
                    height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab buttons
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _BarItem(
                        tab: tabs[i],
                        isActive: i == currentIndex,
                        isDark: isDark,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final _TabDef tab;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _BarItem({
    required this.tab,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.brandBlue;
    final inactiveColor = isDark ? AppTheme.darkBlueTextLight : AppTheme.textLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                key: ValueKey(isActive),
                color: isActive ? activeColor : inactiveColor,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}
