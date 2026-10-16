import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scholai_app/core/theme/app_theme.dart';

/// Bottom navigation shell for Check In, Journal, Habits, Trends.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surfaceMid,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        selectedIndex: _indexFromLocation(location),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: AppColors.primary),
            label: 'Check In',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note, color: AppColors.primary),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement, color: AppColors.primary),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
            label: 'Trends',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/trends')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/journal');
      case 2:
        context.go('/habits');
      case 3:
        context.go('/trends');
    }
  }
}
