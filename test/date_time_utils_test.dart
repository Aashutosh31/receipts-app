import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils.canCheckInForDay', () {
    test('today is always allowed', () {
      final now = DateTime(2026, 9, 30, 22, 10);
      expect(
        DateTimeUtils.canCheckInForDay(
          serverNowLocal: now,
          targetDay: DateTime(2026, 9, 30),
        ),
        isTrue,
      );
    });

    test('yesterday allowed inside 03:00 grace window', () {
      final now = DateTime(2026, 10, 1, 2, 59);
      expect(
        DateTimeUtils.canCheckInForDay(
          serverNowLocal: now,
          targetDay: DateTime(2026, 9, 30),
        ),
        isTrue,
      );
    });

    test('yesterday rejected after grace window', () {
      final now = DateTime(2026, 10, 1, 3, 1);
      expect(
        DateTimeUtils.canCheckInForDay(
          serverNowLocal: now,
          targetDay: DateTime(2026, 9, 30),
        ),
        isFalse,
      );
    });

    test('older history is backfill and rejected', () {
      final now = DateTime(2026, 10, 1, 2, 0);
      expect(
        DateTimeUtils.isBackfill(
          serverNowLocal: now,
          targetDay: DateTime(2026, 9, 28),
        ),
        isTrue,
      );
    });
  });

  group('DateTimeUtils.canFileExcuse', () {
    test('within 48h of the missed day is allowed', () {
      final missedMidnight = DateTime.utc(2026, 9, 28);
      final now = DateTime.utc(2026, 9, 29, 12);
      expect(
        DateTimeUtils.canFileExcuse(
          serverNowUtc: now,
          missedDayUtcMidnight: missedMidnight,
        ),
        isTrue,
      );
    });

    test('after 48h is rejected', () {
      final missedMidnight = DateTime.utc(2026, 9, 28);
      final now = DateTime.utc(2026, 9, 30, 0, 1);
      expect(
        DateTimeUtils.canFileExcuse(
          serverNowUtc: now,
          missedDayUtcMidnight: missedMidnight,
        ),
        isFalse,
      );
    });

    test('future day is rejected', () {
      final now = DateTime.utc(2026, 9, 28);
      final missedMidnight = DateTime.utc(2026, 9, 29);
      expect(
        DateTimeUtils.canFileExcuse(
          serverNowUtc: now,
          missedDayUtcMidnight: missedMidnight,
        ),
        isFalse,
      );
    });
  });
}
