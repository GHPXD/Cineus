import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab(labelKey: _TabLabel.home, icon: Icons.home_rounded, path: '/home'),
    _Tab(
      labelKey: _TabLabel.films,
      icon: Icons.movie_filter_rounded,
      path: '/stages',
    ),
    _Tab(
      labelKey: _TabLabel.posters,
      icon: Icons.blur_on_rounded,
      path: '/visual',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/stages')) return 1;
    if (location.startsWith('/visual')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: child,
      bottomNavigationBar: _BottomNav(
        selectedIndex: selected,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

enum _TabLabel { home, films, posters }

class _Tab {
  final _TabLabel labelKey;
  final IconData icon;
  final String path;
  const _Tab({required this.labelKey, required this.icon, required this.path});

  String label(BuildContext context) => switch (labelKey) {
    _TabLabel.home => context.l10n.navHome,
    _TabLabel.films => context.l10n.navFilms,
    _TabLabel.posters => context.l10n.navPosters,
  };
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidian900,
        border: Border(
          top: BorderSide(color: AppColors.obsidian700, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: tab.label(context),
                  // Declared here too: `excludeSemantics` drops the
                  // GestureDetector's own tap action.
                  onTap: () => onTap(i),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.gold300
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label(context),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.gold300
                                : AppColors.textTertiary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
