import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/color_repository.dart';
import '../../l10n/app_l10n.dart';
import '../providers/color_providers.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import '../widgets/cinematic_app_bar.dart';
import 'color_session_screen.dart';

class ColorHubScreen extends ConsumerStatefulWidget {
  final bool showBack;
  const ColorHubScreen({super.key, this.showBack = true});
  @override
  ConsumerState<ColorHubScreen> createState() => _ColorHubScreenState();
}

class _ColorHubScreenState extends ConsumerState<ColorHubScreen>
    with WidgetsBindingObserver {
  ColorSessionKind _filter = ColorSessionKind.daily;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _reload() {
    ref.invalidate(colorSessionsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _open(String route) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await context.push(route);
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        _reload();
      }
    }
  }

  String _resumeRoute(SavedColorSession session) =>
      '/colors/session/${Uri.encodeComponent(session.id)}';

  String _score(SavedColorSession session) => NumberFormat(
    '0.00',
    Localizations.localeOf(context).languageCode,
  ).format(session.game.averageCents! / 100);
  Widget _card({
    required CineusAssetId icon,
    required String title,
    required String body,
    required String action,
    required VoidCallback onTap,
    String? tag,
    Key? key,
  }) => Container(
    key: key,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.obsidian800,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.obsidian600),
      gradient: const LinearGradient(
        colors: [AppColors.obsidian800, AppColors.obsidian950],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineusIcon(icon, size: 36),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTypography.sectionTitle)),
          ],
        ),
        const SizedBox(height: 12),
        if (tag != null) ...[
          Text(
            tag,
            style: AppTypography.monoSmall.copyWith(color: AppColors.gold300),
          ),
          const SizedBox(height: 8),
        ],
        Text(body, style: AppTypography.bodyMedium),
        const SizedBox(height: 16),
        FilledButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final snapshot = ref.watch(colorSessionsProvider);
    if (snapshot.isLoading || snapshot.hasError) {
      return ColorLoadState(
        failed: snapshot.hasError,
        onBack: widget.showBack ? _back : null,
        onRetry: () => setState(_reload),
      );
    }
    final sessions = snapshot.requireValue;
    final completed = sessions.where((s) => s.status == 'completed').toList();
    final results = completed.where((s) => s.kind == _filter).toList();
    return Scaffold(
      appBar: CinematicAppBar(
        onBack: widget.showBack ? _back : null,
        title: l.colorHistory,
        textScaler: MediaQuery.textScalerOf(context),
        asset: CineusAssetId.completed,
        actions: [
          IconButton(
            onPressed: () => _open('/colors/guide'),
            tooltip: l.colorGuideTitle,
            icon: const CineusIcon(CineusAssetId.help),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            key: const ValueKey('colors-hub-scroll'),
            padding: const EdgeInsets.all(20),
            children: [
              for (final pending in sessions.where(
                (s) => s.kind == ColorSessionKind.daily && s.status == 'active',
              ))
                _card(
                  icon: CineusAssetId.inProgress,
                  title: l.colorPendingDaily,
                  tag: '${pending.dailyDate} · UTC',
                  body: l.colorOldDailyPolicy,
                  action: l.colorResumeRound(pending.game.round),
                  onTap: () => _open(_resumeRoute(pending)),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final kind in ColorSessionKind.values)
                    ChoiceChip(
                      key: ValueKey('colors-history-${kind.name}'),
                      label: Text(
                        kind == ColorSessionKind.daily
                            ? l.colorDailyTitle
                            : l.colorStagesAndTraining,
                      ),
                      selected: _filter == kind,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = kind),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (results.isEmpty) ...[
                const CineusStateArt(CineusStateKind.empty),
                Text(
                  l.colorHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
              ],
              for (final session in results)
                _card(
                  icon: CineusAssetId.completed,
                  title: l.colorScoreValue(_score(session)),
                  tag:
                      (session.isStage
                          ? l.colorStageTitle(session.stageId!)
                          : session.dailyDate) ??
                      DateFormat.yMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(session.updatedAt.toLocal()),
                  body: l.colorHistoryFive,
                  action: l.colorSeeResult,
                  onTap: () => _open(_resumeRoute(session)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
