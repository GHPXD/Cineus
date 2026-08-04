import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/daily_reminder_time.dart';

/// Schedules the daily reminder (D4).
///
/// Behind an interface so the notifier that drives it can be unit-tested: the
/// plugin needs a platform channel, which no widget test provides.
abstract class NotificationService {
  /// Prepares the plugin. Safe to call more than once.
  Future<void> init();

  /// Asks the OS for permission, returning whether it was granted.
  ///
  /// Android 13+ and iOS both require this at runtime. Only ever called from a
  /// player action, never on startup.
  Future<bool> requestPermission();

  /// Whether permission is currently granted, without prompting.
  Future<bool> hasPermission();

  /// Schedules (or reschedules) the daily reminder.
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
  });

  Future<void> cancelDailyReminder();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'cineus_daily';

  bool _initialised = false;

  @override
  Future<void> init() async {
    if (_initialised || kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _resolveTimeZone()));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Deferred: the prompt belongs to the moment the player flips the
          // switch, not to app startup.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    _initialised = true;
  }

  /// Best-effort local zone name. Falls back to UTC, which only shifts the
  /// reminder — it never breaks scheduling.
  Future<String> _resolveTimeZone() async {
    try {
      final offset = DateTime.now().timeZoneOffset;
      // `timezone` needs a location name; derive a fixed-offset Etc/GMT zone,
      // which is exact for the purpose of firing at a local wall-clock hour.
      final hours = -offset.inHours; // Etc/GMT signs are inverted
      if (offset.inMinutes % 60 != 0) return 'UTC';
      if (hours == 0) return 'UTC';
      return hours > 0 ? 'Etc/GMT+$hours' : 'Etc/GMT-${-hours}';
    } catch (_) {
      return 'UTC';
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      return await darwin.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    return false;
  }

  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  @override
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await init();
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    final next = DailyReminderTime.nextOccurrence(
      DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second),
    );
    final scheduled = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Desafio diário',
          channelDescription: 'Aviso de que o desafio do dia está disponível',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact on purpose: an exact alarm would need SCHEDULE_EXACT_ALARM,
      // which Android 14 gates behind a special-access screen. A reminder does
      // not need to-the-second delivery.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: _dailyReminderId);
  }
}
