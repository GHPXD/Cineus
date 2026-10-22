import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/friend_code.dart';
import '../../data/services/friendly_challenges.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/growth_provider.dart';
import '../providers/providers.dart';
import '../providers/progress_provider.dart';
import '../providers/play_notifier.dart';
import '../providers/telemetry_provider.dart';
import '../widgets/cinematic_app_bar.dart';
import '../visuals/cineus_assets.dart';

final friendlyGamesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(growthGatewayProvider);
  if (api == null) return [];
  await FriendlyChallenges(ref.read(databaseProvider), api).flush();
  final result = await api.command('friend_list');
  return (result['games'] as List)
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();
});

class FriendsScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const FriendsScreen({super.key, this.initialCode});
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsState();
}

class _FriendsState extends ConsumerState<FriendsScreen> {
  late final _code = TextEditingController(text: widget.initialCode);
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await task();
    } catch (_) {
      if (mounted) setState(() => _message = context.l10n.friendActionFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(friendlyGamesProvider);
      }
    }
  }

  Future<void> _join() async {
    final code = FriendCode.parse(_code.text);
    if (code == null) throw const FormatException('Invalid invitation');
    final api = ref.read(growthGatewayProvider)!;
    final database = ref.read(databaseProvider);
    final telemetry = ref.read(productTelemetryProvider);
    final value = await api.command('friend_join', {'code': code});
    final mode = GameMode.values.byName(value['mode'] as String);
    final game = ref.read(
      (mode == GameMode.clue ? clueGameProvider : posterGameProvider).notifier,
    );
    if (!await game.loadChallenge(value['movie'] as int, invitation: code)) {
      throw StateError('Could not load challenge');
    }
    final session = ref
        .read(mode == GameMode.clue ? clueGameProvider : posterGameProvider)
        .session;
    if (session?.id == null) throw StateError('Missing game');
    final pending = FriendlyChallenges(database, api);
    await pending.attach(session!.id!, code);
    await pending.flush();
    await telemetry.record('invite_joined', properties: {'mode': mode.name});
    if (mounted) {
      await context.push(
        '${mode == GameMode.clue ? '/game' : '/visual/play'}?source=challenge',
      );
    }
  }

  Future<void> _create() async {
    final progress = ref.read(progressRepositoryProvider),
        api = ref.read(growthGatewayProvider)!;
    final telemetry = ref.read(productTelemetryProvider);
    final options = [
      ...await progress.films(GameMode.clue, ActivityScope.all),
      ...await progress.films(GameMode.poster, ActivityScope.all),
    ]..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    if (!mounted) return;
    if (options.isEmpty) {
      setState(() => _message = context.l10n.friendPlayFirst);
      return;
    }
    final chosen = await showModalBottomSheet<GameSession>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(context.l10n.friendChooseGame),
            ),
            for (final s in options.take(12))
              ListTile(
                title: Text(
                  '${s.mode == GameMode.clue ? context.l10n.modeClues : context.l10n.modePoster} · #${s.movieId}',
                ),
                subtitle: Text(context.l10n.resultScore(s.score)),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    final value = await api.command('friend_create', {
      'mode': chosen.mode.name,
      'movie': chosen.movieId,
      'score': chosen.score,
      'assisted': chosen.extraHints.isNotEmpty,
    });
    final code = value['code'] as String;
    await telemetry.record(
      'invite_created',
      properties: {'mode': chosen.mode.name},
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.friendCreated),
        content: SelectableText('${FriendCode.link(code)}\n\n$code'),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '${FriendCode.link(code)}'),
              );
            },
            child: Text(context.l10n.copyResultText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.back),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n,
        available = ref.watch(growthGatewayProvider) != null;
    final games = ref.watch(friendlyGamesProvider);
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.friendGames,
        asset: CineusAssetId.challenge,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.friendPrivateRules),
          const SizedBox(height: 16),
          if (!available) Text(l.connectedRequired),
          FilledButton(
            onPressed: _busy || !available ? null : () => _run(_create),
            child: Text(l.friendCreate),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            maxLength: 2048,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l.challengeInputLabel),
          ),
          OutlinedButton(
            onPressed: _busy || !available ? null : () => _run(_join),
            child: Text(l.friendJoin),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_message != null) Text(_message!),
          const SizedBox(height: 20),
          games.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => TextButton(
              onPressed: () => ref.invalidate(friendlyGamesProvider),
              child: Text(l.retryAction),
            ),
            data: (rows) => Column(
              children: [
                for (final row in rows)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${row['mode'] == 'clue' ? l.modeClues : l.modePoster} · ${row['code']}',
                      ),
                      subtitle: Text(
                        '${l.friendYou}: ${row[row['host'] == true ? 'host_score' : 'guest_score'] ?? '—'}${row[row['host'] == true ? 'host_assisted' : 'guest_assisted'] == true ? ' · ${l.assistedResult}' : ''}\n${l.friendOther}: ${row[row['host'] == true ? 'guest_score' : 'host_score'] ?? '—'}${row[row['host'] == true ? 'guest_assisted' : 'host_assisted'] == true ? ' · ${l.assistedResult}' : ''}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(friendlyGamesProvider),
            child: Text(l.retryAction),
          ),
        ],
      ),
    );
  }
}
