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
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/stages')) return 1;
    if (location.startsWith('/visual')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    void navigate(int index) => context.go(_tabs[index].path);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;
        if (useRail) {
          return Scaffold(
            backgroundColor: AppColors.obsidian950,
            body: SafeArea(
              child: Row(
                children: [
                  _SideNav(
                    selectedIndex: selected,
                    tabs: _tabs,
                    onTap: navigate,
                  ),
                  const VerticalDivider(width: 1, thickness: 0.5),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.obsidian950,
          body: child,
          bottomNavigationBar: _BottomNav(
            selectedIndex: selected,
            tabs: _tabs,
            onTap: navigate,
          ),
        );
      },
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

class _SideNav extends StatelessWidget {
  final int selectedIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  const _SideNav({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidian900,
      child: NavigationRail(
        backgroundColor: AppColors.obsidian900,
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.35,
        minWidth: 84,
        selectedIconTheme: const IconThemeData(
          color: AppColors.obsidian900,
          size: 23,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textTertiary,
          size: 22,
        ),
        selectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.gold300,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
        unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontSize: 11,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.gold300,
        destinations: [
          for (final tab in tabs)
            NavigationRailDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.icon),
              label: Text(tab.label(context)),
            ),
        ],
      ),
    );
  }
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
      decoration: const BoxDecoration(
        color: AppColors.obsidian900,
        border: Border(
          top: BorderSide(color: AppColors.obsidian700, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: tab.label(context),
                  onTap: () => onTap(i),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          size: 23,
                          color: selected
                              ? AppColors.gold300
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label(context),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.2,
                            color: selected
                                ? AppColors.gold300
                                : AppColors.textTertiary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
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