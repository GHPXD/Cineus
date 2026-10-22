import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/cinematic_app_bar.dart';
import '../l10n_mappers.dart';
import '../widgets/settings_section.dart';
import '../visuals/cineus_assets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      appBar: CinematicAppBar(
        title: context.l10n.settingsTitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
        textScaler: MediaQuery.textScalerOf(context),
        asset: CineusAssetId.settings,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: const [SettingsSection()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
