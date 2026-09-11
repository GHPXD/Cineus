import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/platform/device_time_zone.dart';
import '../../core/utils/daily_reminder_time.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });
  Future<void> cancelDailyReminder();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final DeviceTimeZoneResolver _timeZoneResolver;

  NotificationServiceImpl({
    FlutterLocalNotificationsPlugin? plugin,
    DeviceTimeZoneResolver? timeZoneResolver,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _timeZoneResolver = timeZoneResolver ??
            const DeviceTimeZoneResolver(MethodChannelDeviceTimeZoneProvider());

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'cineus_daily';
  bool _initialised = false;

  @override
  Future<void> init() async {
    if (_initialised || kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(await _timeZoneResolver.resolve());

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
    required String channelName,
    required String channelDescription,
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
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
