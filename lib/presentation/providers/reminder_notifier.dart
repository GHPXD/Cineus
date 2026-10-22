import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_service.dart';
import '../../domain/repositories/app_meta_repository.dart';
import '../../l10n/app_l10n.dart';
import 'locale_notifier.dart';
import 'providers.dart';

class ReminderState {
  final bool enabled;
  final bool busy;
  final bool permissionDenied;
  final bool hasError;

  const ReminderState({
    this.enabled = false,
    this.busy = false,
    this.permissionDenied = false,
    this.hasError = false,
  });

  ReminderState copyWith({
    bool? enabled,
    bool? busy,
    bool? permissionDenied,
    bool? hasError,
  }) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      busy: busy ?? this.busy,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      hasError: hasError ?? this.hasError,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final NotificationService _service;
  final AppMetaRepository _meta;
  final Future<AppL10n> Function() _l10n;

  static const _key = 'daily_reminder_enabled';
  late final Future<void> ready;
  bool? _retryValue;
  bool _retryCopy = false;

  ReminderNotifier({
    required NotificationService service,
    required AppMetaRepository meta,
    required Future<AppL10n> Function() l10n,
  }) : _service = service,
       _meta = meta,
       _l10n = l10n,
       super(const ReminderState(busy: true)) {
    ready = _restore();
  }

  Future<void> _restore() async {
    try {
      final stored = await _meta.read(_key);
      if (!mounted) return;
      if (stored != 'true') {
        state = const ReminderState();
        return;
      }
      if (!await _service.hasPermission()) {
        await _meta.write(_key, 'false');
        if (mounted) state = const ReminderState();
        return;
      }
      await _schedule();
      if (mounted) state = const ReminderState(enabled: true);
    } catch (_) {
      if (mounted) state = const ReminderState(hasError: true);
    }
  }

  Future<void> toggle(bool value) async {
    if (!mounted || state.busy) return;
    _retryValue = value;
    _retryCopy = false;
    var enabled = state.enabled;
    var scheduled = false;
    state = state.copyWith(
      busy: true,
      permissionDenied: false,
      hasError: false,
    );
    try {
      if (!value) {
        await _service.cancelDailyReminder();
        enabled = false;
        await _meta.write(_key, 'false');
        if (mounted) state = const ReminderState();
        return;
      }
      final granted = await _service.requestPermission();
      if (!granted) {
        enabled = false;
        await _meta.write(_key, 'false');
        if (mounted) state = const ReminderState(permissionDenied: true);
        return;
      }
      await _schedule();
      scheduled = true;
      enabled = true;
      await _meta.write(_key, 'true');
      if (mounted) state = const ReminderState(enabled: true);
    } catch (_) {
      // A notification must not outlive a failed preference commit.
      if (scheduled) {
        try {
          await _service.cancelDailyReminder();
          enabled = false;
        } catch (_) {
          // Preserve the last known state; do not promise successful cancellation.
        }
      }
      if (mounted) state = ReminderState(enabled: enabled, hasError: true);
    }
  }

  Future<void> refreshCopy() async {
    if (!mounted || !state.enabled || state.busy) return;
    _retryCopy = true;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _schedule();
      if (mounted) state = const ReminderState(enabled: true);
    } catch (_) {
      if (mounted) state = const ReminderState(enabled: true, hasError: true);
    }
  }

  Future<void> retry() async {
    if (!mounted || state.busy) return;
    if (_retryCopy) {
      await refreshCopy();
    } else if (_retryValue != null) {
      await toggle(_retryValue!);
    } else {
      state = state.copyWith(busy: true, hasError: false);
      await _restore();
    }
  }

  Future<void> _schedule() async {
    final l10n = await _l10n();
    if (!mounted) return;
    await _service.scheduleDailyReminder(
      title: l10n.reminderTitle,
      body: l10n.reminderBody,
      channelName: l10n.reminderSettingTitle,
      channelDescription: l10n.reminderSettingSubtitle,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationServiceImpl();
});

final reminderNotifierProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
      return ReminderNotifier(
        service: ref.read(notificationServiceProvider),
        meta: ref.read(appMetaRepositoryProvider),
        l10n: () async {
          final locale =
              ref.read(localeNotifierProvider) ??
              PlatformDispatcher.instance.locale;
          final supported =
              LocaleNotifier.supportedLocales.any(
                (l) => l.languageCode == locale.languageCode,
              )
              ? Locale(locale.languageCode)
              : const Locale('pt');
          return AppL10n.delegate.load(supported);
        },
      );
    });
