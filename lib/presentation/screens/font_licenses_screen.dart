import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';

class FontLicensesScreen extends StatefulWidget {
  const FontLicensesScreen({super.key});
  @override
  State<FontLicensesScreen> createState() => _FontLicensesScreenState();
}

class _FontLicensesScreenState extends State<FontLicensesScreen> {
  static const files = {
    'Fredoka': 'Fredoka-OFL.txt',
    'Nunito': 'Nunito-OFL.txt',
  };
  String selected = files.keys.first;
  late Future<String> content = _load();
  Future<String> _load() =>
      rootBundle.loadString('assets/licenses/${files[selected]}');
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l.semBack,
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/about'),
                        icon: const CineusIcon(CineusAssetId.back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.fontLicensesTitle,
                          style: AppTypography.pageTitle,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in files.keys)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text(name),
                          selected: selected == name,
                          onSelected: (_) => setState(() {
                            selected = name;
                            content = _load();
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<String>(
                    future: content,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(l.fontLicenseFailed),
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  content = _load();
                                }),
                                icon: const CineusIcon(CineusAssetId.retry),
                                label: Text(l.retryAction),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return SingleChildScrollView(
                        key: ValueKey(selected),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: SelectableText(
                          snapshot.data!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
