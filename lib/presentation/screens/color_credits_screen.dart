import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cinematic_app_bar.dart';
import 'color_session_screen.dart';

class ColorCreditsScreen extends StatefulWidget {
  const ColorCreditsScreen({super.key});
  @override
  State<ColorCreditsScreen> createState() => _ColorCreditsScreenState();
}

class _ColorCreditsScreenState extends State<ColorCreditsScreen> {
  late Future<List<dynamic>> _rows = _load();
  Future<List<dynamic>> _load() async =>
      (jsonDecode(
                await rootBundle.loadString(
                  'assets/credits/colors_sources.json',
                ),
              )
              as Map<String, dynamic>)['characters']
          as List;
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/colors');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context),
        locale = Localizations.localeOf(context).languageCode;
    return FutureBuilder<List<dynamic>>(
      future: _rows,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ColorLoadState(
            failed: snapshot.hasError,
            onBack: _back,
            onRetry: () => setState(() => _rows = _load()),
          );
        }
        return Scaffold(
          appBar: CinematicAppBar(
            title: l.colorCreditsTitle,
            onBack: _back,
            textScaler: MediaQuery.textScalerOf(context),
            asset: CineusAssetId.information,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                key: const ValueKey('colors-credits-scroll'),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l.colorCreditsDescription,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  for (final row in snapshot.data!)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.obsidian800,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.obsidian600),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            (row['copy'][locale] ??
                                    row['copy']['en'])['character']
                                as String,
                            style: AppTypography.sectionTitle,
                          ),
                          Text(
                            (row['copy'][locale] ?? row['copy']['en'])['work']
                                as String,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            row['art_origin'] == 'generated'
                                ? l.colorCreditsGenerated
                                : l.colorCreditsReference,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.colorCreditsStudy,
                            style: AppTypography.labelLarge,
                          ),
                          SelectableText(
                            row['study_url'] as String,
                            style: AppTypography.bodySmall,
                          ),
                          for (final url in row['art_urls'] as List) ...[
                            const SizedBox(height: 12),
                            Text(
                              l.colorCreditsArt,
                              style: AppTypography.labelLarge,
                            ),
                            SelectableText(
                              url as String,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
