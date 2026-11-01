import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/utils/app_router.dart';

/// Bottom navigation shell for Check In, Journal, Habits, Trends.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final place = location.split('?').first;
    if (AppRouter.resumePlaces.contains(place)) {
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.getString('last_place') != place) {
          prefs.setString('last_place', place);
        }
      });
    }

    final selected = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surfaceMid,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, item) in _items.indexed)
                  _PillItem(
                    item: item,
                    selected: i == selected,
                    onTap: () => _onTap(context, i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _items = [
    _NavItem(Icons.light_mode_outlined, Icons.light_mode, 'Check In'),
    _NavItem(Icons.auto_stories_outlined, Icons.auto_stories, 'Journal'),
    _NavItem(Icons.spa_outlined, Icons.spa, 'Habits'),
    _NavItem(Icons.insights_outlined, Icons.insights, 'Trends'),
  ];

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

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: selected ? AppColors.primaryLight : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
