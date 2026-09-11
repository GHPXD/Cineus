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

  const ReminderState({
    this.enabled = false,
    this.busy = false,
    this.permissionDenied = false,
  });

  ReminderState copyWith({bool? enabled, bool? busy, bool? permissionDenied}) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      busy: busy ?? this.busy,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final NotificationService _service;
  final AppMetaRepository _meta;
  final Future<AppL10n> Function() _l10n;

  static const _key = 'daily_reminder_enabled';

  ReminderNotifier({
    required NotificationService service,
    required AppMetaRepository meta,
    required Future<AppL10n> Function() l10n,
  })  : _service = service,
        _meta = meta,
        _l10n = l10n,
        super(const ReminderState()) {
    _restore();
  }

  Future<void> _restore() async {
    final stored = await _meta.read(_key);
    if (stored != 'true') return;

    if (!await _service.hasPermission()) {
      state = const ReminderState(enabled: false);
      await _meta.write(_key, 'false');
      return;
    }

    state = const ReminderState(enabled: true);
    await _schedule();
  }

  Future<void> toggle(bool value) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, permissionDenied: false);

    if (!value) {
      await _service.cancelDailyReminder();
      await _meta.write(_key, 'false');
      state = const ReminderState(enabled: false);
      return;
    }

    final granted = await _service.requestPermission();
    if (!granted) {
      await _meta.write(_key, 'false');
      state = const ReminderState(enabled: false, permissionDenied: true);
      return;
    }

    await _meta.write(_key, 'true');
    await _schedule();
    state = const ReminderState(enabled: true);
  }

  Future<void> refreshCopy() async {
    if (!state.enabled) return;
    await _schedule();
  }

  Future<void> _schedule() async {
    final l10n = await _l10n();
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
      final locale = ref.read(localeNotifierProvider) ??
          PlatformDispatcher.instance.locale;
      final supported = AppL10n.supportedLocales
              .any((l) => l.languageCode == locale.languageCode)
          ? Locale(locale.languageCode)
          : const Locale('pt');
      return AppL10n.delegate.load(supported);
    },
  );
});
