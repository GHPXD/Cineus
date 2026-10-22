import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../core/utils/trusted_time.dart';

/// Injectable wall clock for lifecycle/rollover and reproducible UI evidence.
final appTrustedTimeProvider = Provider((_) => TrustedTime());
final appClockProvider = Provider<DateTime Function()>(
  (ref) => ref.read(appTrustedTimeProvider).now,
);

/// Only changes when the UTC date changes, so daily queries do not run per tick.
final dailyDateProvider = StateProvider<String>(
  (ref) => DailySelector.todayKey(ref.read(appClockProvider)()),
);
