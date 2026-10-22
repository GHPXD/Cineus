import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  static const _tabs = [
    _Tab(labelKey: _TabLabel.home, icon: CineusAssetId.home),
    _Tab(labelKey: _TabLabel.films, icon: CineusAssetId.modeClues),
    _Tab(labelKey: _TabLabel.posters, icon: CineusAssetId.modePoster),
    _Tab(labelKey: _TabLabel.colors, icon: CineusAssetId.modeColors),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = navigationShell.currentIndex;

    void navigate(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

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
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.obsidian950,
          body: navigationShell,
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

enum _TabLabel { home, films, posters, colors }

class _Tab {
  final _TabLabel labelKey;
  final CineusAssetId icon;

  const _Tab({required this.labelKey, required this.icon});

  String label(BuildContext context) => switch (labelKey) {
    _TabLabel.home => context.l10n.navHome,
    _TabLabel.films => context.l10n.navFilms,
    _TabLabel.posters => context.l10n.navPosters,
    _TabLabel.colors => context.l10n.colorModeTitle,
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
    final scaledLabel = MediaQuery.textScalerOf(context).scale(11);
    final extraWidth = (scaledLabel - 11).clamp(0.0, 24.0);

    return Container(
      color: AppColors.obsidian900,
      child: NavigationRail(
        backgroundColor: AppColors.obsidian900,
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.35,
        minWidth: 84 + extraWidth,
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
              icon: CineusIcon(tab.icon, color: AppColors.textSecondary),
              selectedIcon: CineusIcon(tab.icon, color: AppColors.obsidian900),
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
    final scaledLabel = MediaQuery.textScalerOf(context).scale(11);
    final largeLabels = scaledLabel > 15;
    final height = largeLabels ? 44 + scaledLabel * 2.5 : 76.0;
    int labelWeight(_Tab tab) {
      if (!largeLabels) return 1;
      final painter = TextPainter(
        text: TextSpan(
          text: tab.label(context),
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout();
      final weight = (painter.width + 8).clamp(48.0, double.infinity).ceil();
      painter.dispose();
      return weight;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF050C14),
        border: Border(
          top: BorderSide(color: AppColors.obsidian700, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == selectedIndex;
              return Expanded(
                flex: labelWeight(tab),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: tab.label(context),
                  onTap: () => onTap(i),
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('nav-${tab.labelKey.name}'),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CineusIcon(
                          tab.icon,
                          size: 28,
                          color: selected
                              ? AppColors.gold300
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            tab.label(context),
                            maxLines: largeLabels ? 2 : 1,
                            textAlign: TextAlign.center,
                            softWrap: largeLabels,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: selected
                                  ? AppColors.gold300
                                  : AppColors.textTertiary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 32,
                          height: 2,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.gold300
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.gold300.withValues(
                                        alpha: .3,
                                      ),
                                      blurRadius: 5,
                                    ),
                                  ]
                                : [],
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
