import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/daily_reminder_time.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
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
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    _initialised = true;
  }

  /// Best-effort fallback until a native IANA-zone source is bundled.
  ///
  /// `timezone` requires an IANA location. Fixed Etc/GMT locations correctly
  /// preserve the current wall-clock offset, but they cannot predict a future
  /// DST transition. The remaining IANA-zone follow-up is tracked in the Phase
  /// 6 hardening plan instead of silently pretending this is fully DST-aware.
  Future<String> _resolveTimeZone() async {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = -offset.inHours;
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
      return await darwin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
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

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    return false;
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