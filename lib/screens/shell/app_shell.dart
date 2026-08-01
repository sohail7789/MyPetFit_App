import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/app_bottom_nav.dart';

/// Root shell hosting the four tabs from the redesign:
/// Home · Report · Shop · Account.
///
/// Each branch keeps its own navigation state, so switching tabs preserves
/// where the user was.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.values[navigationShell.currentIndex],
        onSelect: (tab) => navigationShell.goBranch(
          tab.index,
          // Tapping the active tab pops that branch back to its root.
          initialLocation: tab.index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
