import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import '../providers/daily_calendar_provider.dart';
import '../providers/color_providers.dart';
import '../providers/play_notifier.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/cineus_icon.dart';
import '../visuals/cineus_assets.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});
  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveState();
}

class _ArchiveState extends ConsumerState<ArchiveScreen> {
  int _mode = 0, _limit = 30;
  bool _busy = false;
  String? _error;
  Future<void> _open(String date) async {
    if (_busy) return;
    final l = context.l10n;
    final repo = ref.read(movieRepositoryProvider);
    final calendar = ref.read(dailyCalendarProvider.future);
    final colors = ref.read(colorRepositoryProvider);
    final colorCatalog = ref.read(colorCatalogProvider.future);
    final mode = _mode;
    final game = ref.read(
      (mode == 0 ? clueGameProvider : posterGameProvider).notifier,
    );
    setState(() => _busy = true);
    try {
      if (mode == 2) {
        final record = await colors.archive(await colorCatalog, date);
        if (mounted) {
          await context.push(
            '/colors/session/${Uri.encodeComponent(record.id)}',
          );
        }
      } else {
        final ids = await repo.getMovieIds();
        if (ids.isEmpty) throw StateError('Catalogue empty');
        final m = mode == 0 ? GameMode.clue : GameMode.poster;
        final day = DailySelector.dateFromKey(date)!;
        final id =
            (await calendar).movie(m, date) ??
            ids[mode == 0
                ? DailySelector.movieIndexForDate(ids.length, day)
                : DailySelector.posterMovieIndexForDate(ids.length, day)];
        if (!await game.loadPractice(id, archiveDate: date)) {
          throw StateError('Archive unavailable');
        }
        if (mounted) {
          await context.push(
            '${mode == 0 ? '/game' : '/visual/play'}?source=archive',
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = l.gameLoadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DailySelector.dateFromKey(
      DailySelector.todayKey(ref.read(appClockProvider)()),
    )!;
    final days = today
        .difference(DateTime.utc(2025, 1, 1))
        .inDays
        .clamp(0, _limit);
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.archiveTitle,
        asset: CineusAssetId.homeCalendar,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l.archiveDescription),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ChoiceChip(
                        label: Text(
                          [l.modeClues, l.modePoster, l.colorModeTitle][i],
                        ),
                        selected: _mode == i,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _mode = i),
                      ),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) Text(_error!),
                for (var n = 1; n <= days; n++)
                  Card(
                    child: ListTile(
                      leading: CineusIcon(
                        [
                          CineusAssetId.modeClues,
                          CineusAssetId.modePoster,
                          CineusAssetId.modeColors,
                        ][_mode],
                      ),
                      title: Text(
                        DailySelector.todayKey(
                          today.subtract(Duration(days: n)),
                        ),
                      ),
                      trailing: const CineusIcon(CineusAssetId.chevron),
                      onTap: _busy
                          ? null
                          : () => _open(
                              DailySelector.todayKey(
                                today.subtract(Duration(days: n)),
                              ),
                            ),
                    ),
                  ),
                if (days == _limit)
                  TextButton(
                    onPressed: () => setState(() => _limit += 30),
                    child: Text(l.archiveMore),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
