import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/color_repository.dart';
import '../../domain/entities/color_question.dart';
import '../../domain/entities/color_stats.dart';
import '../../domain/entities/color_stage.dart';
import '../../data/repositories/color_stage_repository.dart';
import 'ticket_notifier.dart';
import 'app_clock.dart';
import 'providers.dart';
import 'daily_calendar_provider.dart';

final colorRepositoryProvider = Provider<ColorRepository>(
  (ref) => ColorRepository(
    ref.read(databaseProvider),
    now: ref.read(appClockProvider),
    schedule: (date) async =>
        (await ref.read(dailyCalendarProvider.future)).colors[date],
  ),
);
final colorCatalogProvider = FutureProvider<ColorPilotCatalog>(
  (ref) async => ColorPilotCatalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/colors/training_v1.json'))
        as Map<String, dynamic>,
  ),
);

final colorSessionsProvider =
    FutureProvider.autoDispose<List<SavedColorSession>>(
      (ref) => ref.watch(colorRepositoryProvider).list(),
    );

final colorStageCatalogProvider = FutureProvider<ColorStageCatalog>((
  ref,
) async {
  final colors = ref.watch(colorCatalogProvider.future);
  final raw = await rootBundle.loadString(
    'assets/colors/stages_v1.json',
    cache: false,
  );
  return ColorStageCatalog.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
    await colors,
  );
});
final colorStageRepositoryProvider = Provider<ColorStageRepository>(
  (ref) => ColorStageRepository(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
  ),
);
final colorStageProgressProvider =
    FutureProvider.autoDispose<List<ColorStageProgress>>((ref) async {
      final catalog = ref.watch(colorStageCatalogProvider.future);
      final records = ref.watch(colorSessionsProvider.future);
      return ColorStageProgress.from(await catalog, await records);
    });

Future<SavedColorSession?> startColorStage(
  WidgetRef ref,
  int stageId,
  int match,
) async {
  // Capture dependencies before awaits, including when the caller leaves.
  final tickets = ref.read(ticketNotifierProvider.notifier);
  final stages = ref.read(colorStageRepositoryProvider);
  final catalogFuture = ref.read(colorStageCatalogProvider.future);
  final catalog = await catalogFuture;
  await stages.prepare();
  return tickets.purchaseOnce(
    existing: (db) => stages.existing(db, catalog, stageId, match),
    create: (db) => stages.create(db, catalog, stageId, match),
  );
}

class ColorHomeOverview {
  final SavedColorSession? today, training;
  final ColorStats dailyStats, trainingStats;
  ColorHomeOverview(List<SavedColorSession> sessions, String date)
    : today = sessions.where((s) => s.dailyDate == date).firstOrNull,
      training = sessions
          .where(
            (s) =>
                !s.isStage &&
                s.kind == ColorSessionKind.training &&
                s.status == 'active',
          )
          .firstOrNull,
      dailyStats = ColorStats.fromSessions(sessions, ColorSessionKind.daily),
      trainingStats = ColorStats.fromSessions(
        sessions,
        ColorSessionKind.training,
      );
}

final colorHomeOverviewProvider = FutureProvider.autoDispose<ColorHomeOverview>(
  (ref) async {
    final date = ref.watch(dailyDateProvider);
    return ColorHomeOverview(
      await ref.watch(colorSessionsProvider.future),
      date,
    );
  },
);

abstract final class ColorRewards {
  static const amount = 2;
  static Future<bool> claim(
    ColorRepository repository,
    TicketNotifier tickets,
    String id,
  ) async {
    final record = await repository.load(id);
    if (record == null ||
        record.kind != ColorSessionKind.daily ||
        record.status != 'completed') {
      throw StateError('Only completed daily colour games qualify');
    }
    return tickets.creditOnce(
      key: 'colors_daily_${record.dailyDate}',
      amount: amount,
      verify: (db) async {
        final rows = await db.query(
          'color_sessions',
          where: 'id = ? AND kind = ? AND status = ? AND daily_date = ?',
          whereArgs: [id, 'daily', 'completed', record.dailyDate],
          limit: 1,
        );
        if (rows.isEmpty ||
            SavedColorSession.fromRow(rows.single).game.answers.length != 5) {
          throw StateError('Colour result unavailable');
        }
      },
    );
  }
}

final colorDailyRewardProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, id) async {
      final repo = ref.read(colorRepositoryProvider),
          tickets = ref.read(ticketNotifierProvider.notifier);
      await tickets.refreshBalance();
      return ColorRewards.claim(repo, tickets, id);
    });
