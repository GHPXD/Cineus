import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/player_data_provider.dart';
import '../widgets/cineus_icon.dart';
import '../../data/services/population_telemetry.dart';
import '../../data/services/progress_backup.dart';
import '../l10n_mappers.dart';
import '../providers/growth_provider.dart';
import '../providers/providers.dart';
import '../providers/commercial_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/game_actions.dart';
import '../providers/color_providers.dart';
import '../widgets/cinematic_app_bar.dart';
import '../visuals/cineus_assets.dart';

class PlayerDataScreen extends ConsumerStatefulWidget {
  const PlayerDataScreen({super.key});
  @override
  ConsumerState<PlayerDataScreen> createState() => _PlayerDataState();
}

class _PlayerDataState extends ConsumerState<PlayerDataScreen> {
  bool _busy = false, _consent = false, _preferencesLoading = true;
  bool _preferencesFailed = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final consent = await ref.read(usageDataServiceProvider).consented();
      if (mounted) {
        setState(() {
          _consent = consent;
          _preferencesLoading = false;
          _preferencesFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _preferencesFailed = true;
          _preferencesLoading = false;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _message = context.l10n.dataActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup(bool restore) async {
    final api = ref.read(growthGatewayProvider);
    if (api == null) return;
    final backup = ProgressBackup(ref.read(databaseProvider), api);
    final telemetry = ref.read(productTelemetryProvider);
    final refresh = ref.read(finishedGameRefreshProvider);
    if (restore) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.backupRestore),
          content: Text(context.l10n.backupConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.back),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.backupRestore),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await backup.restore();
      refresh();
      if (mounted) {
        ref.invalidate(colorSessionsProvider);
        ref.invalidate(colorStageProgressProvider);
      }
    } else {
      await backup.save();
    }
    if (mounted) ref.invalidate(cloudBackupStatusProvider);
    await telemetry.record(restore ? 'backup_restored' : 'backup_saved');
    if (mounted) {
      setState(
        () => _message = restore
            ? context.l10n.backupRestored
            : context.l10n.backupSaved,
      );
    }
  }

  Future<void> _identity(bool recover) async {
    final sync = ref.read(commerceSynchronizerProvider);
    final tickets = ref.read(ticketNotifierProvider.notifier);
    if (sync == null) return;
    if (!recover) await sync.synchronize();
    if (!mounted) return;
    final input = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.backupCode),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.recoveryKeepPrivate),
                const SizedBox(height: 12),
                if (recover)
                  TextField(
                    controller: input,
                    obscureText: true,
                    maxLength: 80,
                    autocorrect: false,
                    enableSuggestions: false,
                  )
                else
                  SelectableText(
                    '${sync.identity!.owner}.${sync.identity!.recovery}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.back),
            ),
            if (recover)
              FilledButton(
                onPressed: () => Navigator.pop(context, input.text),
                child: Text(context.l10n.backupRestore),
              ),
          ],
        ),
      );
      if (value != null) {
        await sync.recoverIdentity(value);
        try {
          await tickets.refreshPaidBalance();
        } catch (_) {
          // The authoritative purchased balance retries on foreground.
        }
        if (mounted) ref.invalidate(cloudBackupStatusProvider);
        if (mounted) await _backup(true);
      }
    } finally {
      input.dispose();
    }
  }

  Future<void> _deleteBackup() async {
    final l = context.l10n;
    final api = ref.read(growthGatewayProvider);
    if (api == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.backupDelete),
        content: Text(l.backupDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.backupDelete),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await api.command('backup_delete');
    if (mounted) {
      ref.invalidate(cloudBackupStatusProvider);
      setState(() => _message = l.backupDeleted);
    }
  }

  Future<void> _consentChange(bool enabled, {bool erase = false}) async {
    final metrics = ref.read(usageDataServiceProvider);
    final online = ref.read(growthGatewayProvider) != null;
    await metrics.setConsent(enabled);
    if (mounted) setState(() => _consent = enabled);
    try {
      await metrics.flush();
      // A previous upload may have been in flight when consent changed.
      if (await metrics.preferencePending()) await metrics.flush();
    } catch (_) {
      /* Revocation remains persisted for the next foreground. */
    }
    final pending = await metrics.preferencePending();
    if (erase && mounted) {
      setState(
        () => _message = !online
            ? context.l10n.metricsDeletedLocal
            : pending
            ? context.l10n.metricsDeletionQueued
            : context.l10n.metricsDeleted,
      );
    }
  }

  String _cloudLabel(AsyncValue<CloudBackupStatus?> status, bool configured) {
    final l = context.l10n;
    if (!configured) return l.backupCloudUnavailable;
    if (status.isLoading) return l.backupCloudChecking;
    if (status.hasError) return l.backupCloudError;
    final saved = status.valueOrNull;
    if (saved == null || !saved.exists) return l.backupCloudEmpty;
    return l.backupCloudLastSaved(
      DateFormat.yMMMd(l.localeName).add_Hm().format(saved.savedAt!.toLocal()),
    );
  }

  Future<void> _manageProgress() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, sheetRef, _) => StatefulBuilder(
          builder: (context, setSheetState) {
            final l = context.l10n;
            final configured = sheetRef.watch(growthGatewayProvider) != null;
            final status = sheetRef.watch(cloudBackupStatusProvider);
            final exists = status.valueOrNull?.exists;
            Future<void> perform(Future<void> Function() action) async {
              final operation = _run(action);
              setSheetState(() {});
              await operation;
              if (context.mounted) setSheetState(() {});
            }

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .86,
                ),
                child: SingleChildScrollView(
                  key: const ValueKey('progress-options-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.backupTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_cloudLabel(status, configured)),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const ValueKey('backup-save'),
                        onPressed: _busy || !configured
                            ? null
                            : () => perform(() => _backup(false)),
                        child: Text(l.backupSave),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('backup-restore'),
                        onPressed: _busy || !configured || exists == false
                            ? null
                            : () => perform(() => _backup(true)),
                        child: Text(l.backupRestore),
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        key: const ValueKey('backup-advanced'),
                        tilePadding: EdgeInsets.zero,
                        title: Text(l.backupOptions),
                        trailing: const CineusIcon(
                          CineusAssetId.chevron,
                          size: 18,
                        ),
                        children: [
                          TextButton(
                            key: const ValueKey('backup-key'),
                            onPressed: _busy || !configured
                                ? null
                                : () => perform(() => _identity(false)),
                            child: Text(l.backupCode),
                          ),
                          TextButton(
                            key: const ValueKey('backup-recover-device'),
                            onPressed: _busy || !configured
                                ? null
                                : () => perform(() => _identity(true)),
                            child: Text(l.recoverAnotherDevice),
                          ),
                          TextButton(
                            key: const ValueKey('backup-delete'),
                            onPressed: _busy || !configured || exists == false
                                ? null
                                : () => perform(_deleteBackup),
                            child: Text(l.backupDelete),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(l.backupScope),
                          ),
                        ],
                      ),
                      if (_busy) const LinearProgressIndicator(),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_message!),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final configured = ref.watch(growthGatewayProvider) != null;
    final status = ref.watch(cloudBackupStatusProvider);
    final metricsActive =
        ref.watch(productTelemetryProvider) is PopulationTelemetry;
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.playerDataTitle,
        asset: CineusAssetId.privacy,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/settings'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('player-data-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.backupTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CineusIcon(CineusAssetId.completed, size: 24),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.progressOnDevice)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _cloudLabel(status, configured),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (status.hasError && configured)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => ref.invalidate(cloudBackupStatusProvider),
                        child: Text(l.retryAction),
                      ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      key: const ValueKey('manage-progress'),
                      onPressed: _busy ? null : _manageProgress,
                      child: Text(l.manageProgress),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      key: const ValueKey('usage-consent'),
                      value: _consent && metricsActive,
                      onChanged:
                          _busy ||
                              _preferencesLoading ||
                              _preferencesFailed ||
                              !metricsActive
                          ? null
                          : (enabled) => _run(() => _consentChange(enabled)),
                      title: Text(l.metricsConsent),
                      subtitle: Text(
                        metricsActive
                            ? l.metricsConsentBody
                            : l.metricsUnavailable,
                      ),
                    ),
                    if (_preferencesLoading) const LinearProgressIndicator(),
                    if (_preferencesFailed)
                      TextButton(
                        onPressed: _loadPreferences,
                        child: Text(l.retryAction),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('usage-delete'),
                      onPressed: _busy
                          ? null
                          : () =>
                                _run(() => _consentChange(false, erase: true)),
                      child: Text(l.metricsDelete),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
