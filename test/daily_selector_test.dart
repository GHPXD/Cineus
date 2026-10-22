import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/utils/daily_selector.dart';

void main() {
  group('DailySelector', () {
    // The app defines "day" in UTC so every player gets the same movie at the
    // same instant. These tests use explicit UTC instants: passing a local
    // DateTime would make them pass or fail depending on the machine's zone.
    group('challengeNumber', () {
      test('returns 1 for epoch date', () {
        expect(DailySelector.challengeNumber(DateTime.utc(2025, 1, 1)), 1);
      });

      test('returns 2 for day after epoch', () {
        expect(DailySelector.challengeNumber(DateTime.utc(2025, 1, 2)), 2);
      });

      test('returns correct number for a known date', () {
        // 2025-02-01 is 31 days after the epoch → challenge #32
        expect(DailySelector.challengeNumber(DateTime.utc(2025, 2, 1)), 32);
      });

      test('ignores time component within the same UTC day', () {
        expect(
          DailySelector.challengeNumber(DateTime.utc(2025, 3, 15, 0, 0)),
          DailySelector.challengeNumber(DateTime.utc(2025, 3, 15, 23, 59)),
        );
      });

      test('rolls over at UTC midnight, not local midnight', () {
        final day15 = DailySelector.challengeNumber(
          DateTime.utc(2025, 3, 15, 23, 59),
        );
        final day16 = DailySelector.challengeNumber(
          DateTime.utc(2025, 3, 16, 0, 0),
        );
        expect(day16, day15 + 1);
      });

      test('is timezone-independent for the same instant', () {
        // Same absolute instant expressed in two zones must give one answer.
        final utc = DateTime.utc(2025, 6, 15, 12, 0);
        final shifted = utc.toLocal();
        expect(
          DailySelector.challengeNumber(shifted),
          DailySelector.challengeNumber(utc),
        );
      });
    });

    group('movieIdForDate', () {
      test('returns value between 1 and totalMovies', () {
        const total = 500;
        for (var day = 1; day <= 365; day++) {
          final date = DateTime(2025, 1, 1).add(Duration(days: day - 1));
          final id = DailySelector.movieIdForDate(total, date);
          expect(id, greaterThanOrEqualTo(1));
          expect(id, lessThanOrEqualTo(total));
        }
      });

      test('is deterministic for same date', () {
        final date = DateTime(2025, 6, 15);
        final id1 = DailySelector.movieIdForDate(500, date);
        final id2 = DailySelector.movieIdForDate(500, date);
        expect(id1, id2);
      });

      test('different dates produce different IDs (mostly)', () {
        final ids = <int>{};
        for (var day = 1; day <= 100; day++) {
          final date = DateTime(2025, 1, 1).add(Duration(days: day - 1));
          ids.add(DailySelector.movieIdForDate(500, date));
        }
        // With 500 movies and 100 days, expect reasonable spread
        expect(ids.length, greaterThan(80));
      });
    });

    group('posterMovieIdForDate', () {
      test('returns value between 1 and totalMovies', () {
        const total = 500;
        for (var day = 1; day <= 50; day++) {
          final date = DateTime(2025, 1, 1).add(Duration(days: day - 1));
          final id = DailySelector.posterMovieIdForDate(total, date);
          expect(id, greaterThanOrEqualTo(1));
          expect(id, lessThanOrEqualTo(total));
        }
      });

      test('differs from clue movie ID for same date', () {
        const total = 500;
        for (var day = 1; day <= 365; day++) {
          final date = DateTime(2025, 1, 1).add(Duration(days: day - 1));
          final clueId = DailySelector.movieIdForDate(total, date);
          final posterId = DailySelector.posterMovieIdForDate(total, date);
          expect(
            posterId,
            isNot(clueId),
            reason: 'Day $day: clue=$clueId poster=$posterId',
          );
        }
      });
    });

    group('todayKey', () {
      test('returns YYYY-MM-DD format', () {
        expect(DailySelector.todayKey(DateTime.utc(2025, 3, 5)), '2025-03-05');
      });

      test('pads single-digit months and days', () {
        expect(DailySelector.todayKey(DateTime.utc(2025, 1, 1)), '2025-01-01');
      });

      test('is the UTC day, not the local day', () {
        // 23:30 UTC belongs to that UTC day regardless of the local offset.
        expect(
          DailySelector.todayKey(DateTime.utc(2025, 3, 5, 23, 30)),
          '2025-03-05',
        );
      });
    });

    group('isDailyKey / dateFromKey', () {
      test('accepts plain daily keys', () {
        expect(DailySelector.isDailyKey('2025-08-04'), isTrue);
        expect(
          DailySelector.dateFromKey('2025-08-04'),
          DateTime.utc(2025, 8, 4),
        );
      });

      test('rejects every prefixed mode key', () {
        for (final key in [
          'stage_1_5',
          'visual_2025-08-04',
          'visual_stage_1_5',
          '',
          '2025-08',
          'x2025-08-04',
        ]) {
          expect(DailySelector.isDailyKey(key), isFalse, reason: key);
          expect(DailySelector.dateFromKey(key), isNull, reason: key);
        }
      });

      test('round-trips through todayKey', () {
        final day = DateTime.utc(2026, 2, 9);
        expect(DailySelector.dateFromKey(DailySelector.todayKey(day)), day);
      });
    });

    group('timeUntilNextChallenge', () {
      test('returns positive duration within 24h', () {
        final remaining = DailySelector.timeUntilNextChallenge();
        expect(remaining.inSeconds, greaterThan(0));
        expect(remaining.inHours, lessThanOrEqualTo(24));
      });

      test('counts down to UTC midnight, matching todayKey rollover', () {
        // 21:30 UTC-3 == 00:30 UTC of the next day: the challenge has already
        // rolled over, so the countdown must be ~23h30, not ~2h30.
        final now = DateTime.utc(2026, 8, 5, 0, 30);
        expect(DailySelector.todayKey(now), '2026-08-05');
        expect(
          DailySelector.timeUntilNextChallenge(now).inMinutes,
          23 * 60 + 30,
        );
      });

      test('is zero-length exactly at the rollover instant', () {
        final midnight = DateTime.utc(2026, 8, 5);
        expect(
          DailySelector.timeUntilNextChallenge(midnight),
          const Duration(hours: 24),
        );
      });
    });
  });
}
