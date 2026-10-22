import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_calendar.dart';

final dailyCalendarProvider = FutureProvider<DailyCalendar>(
  (ref) async => DailyCalendar.fromJson(
    jsonDecode(await rootBundle.loadString('assets/daily/calendar_v1.json'))
        as Map<String, dynamic>,
  ),
);
