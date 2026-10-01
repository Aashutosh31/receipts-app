import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';

LedgerEntry _entry({
  required DateTime day,
  required String commitment,
  required String status,
  bool? done,
  bool paused = false,
}) {
  return LedgerEntry(
    day: day,
    commitmentId: commitment,
    commitmentTitle: commitment,
    status: status,
    done: done,
    isPaused: paused,
  );
}

void main() {
  final DateTime today = DateTime.utc(2026, 10, 5);
  final DateTime yesterday = DateTime.utc(2026, 10, 4);
  final DateTime tomorrow = DateTime.utc(2026, 10, 6);

  group('summarizeLedgerDays', () {
    test('all done is kept', () {
      final List<LedgerDay> days = summarizeLedgerDays(<LedgerEntry>[
        _entry(day: yesterday, commitment: 'a', status: 'done', done: true),
        _entry(day: yesterday, commitment: 'b', status: 'done', done: true),
      ], today);
      expect(days, hasLength(1));
      expect(days.first.status, DayStatus.kept);
      expect(days.first.doneCount, 2);
      expect(days.first.totalCount, 2);
    });

    test('one miss means missed', () {
      final List<LedgerDay> days = summarizeLedgerDays(<LedgerEntry>[
        _entry(day: yesterday, commitment: 'a', status: 'done', done: true),
        _entry(day: yesterday, commitment: 'b', status: 'missed', done: false),
      ], today);
      expect(days.first.status, DayStatus.missed);
    });

    test('paused wins over misses', () {
      final List<LedgerDay> days = summarizeLedgerDays(<LedgerEntry>[
        _entry(day: yesterday, commitment: 'a', status: 'paused', paused: true),
        _entry(day: yesterday, commitment: 'b', status: 'missed', done: false),
      ], today);
      expect(days.first.status, DayStatus.paused);
    });

    test('future day is upcoming', () {
      final List<LedgerDay> days = summarizeLedgerDays(<LedgerEntry>[
        _entry(day: tomorrow, commitment: 'a', status: 'promised', done: null),
      ], today);
      expect(days.first.status, DayStatus.upcoming);
    });

    test('days come back sorted', () {
      final List<LedgerDay> days = summarizeLedgerDays(<LedgerEntry>[
        _entry(day: today, commitment: 'a', status: 'missed', done: false),
        _entry(day: yesterday, commitment: 'a', status: 'done', done: true),
      ], today);
      expect(days.map((LedgerDay d) => d.day), <DateTime>[yesterday, today]);
    });
  });

  group('dayNumber', () {
    test('start day is day 1', () {
      expect(
        dayNumber(DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 1)),
        1,
      );
    });

    test('counts forward', () {
      expect(
        dayNumber(DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 5)),
        5,
      );
    });

    test('clamps before start', () {
      expect(
        dayNumber(DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 1)),
        1,
      );
    });
  });

  group('todayStatusLine', () {
    test('paused line', () {
      expect(
        todayStatusLine(
          dayNumber: 4,
          doneCount: 0,
          totalCount: 3,
          streak: 3,
          isPaused: true,
        ),
        contains('Paused'),
      );
    });

    test('all done line', () {
      expect(
        todayStatusLine(
          dayNumber: 4,
          doneCount: 3,
          totalCount: 3,
          streak: 4,
          isPaused: false,
        ),
        contains('All 3 done'),
      );
    });

    test('partial line names what is left', () {
      expect(
        todayStatusLine(
          dayNumber: 4,
          doneCount: 1,
          totalCount: 3,
          streak: 2,
          isPaused: false,
        ),
        contains('2 left'),
      );
    });

    test('empty day line', () {
      expect(
        todayStatusLine(
          dayNumber: 4,
          doneCount: 0,
          totalCount: 3,
          streak: 2,
          isPaused: false,
        ),
        contains('Nothing logged yet'),
      );
    });
  });

  group('server day round trip', () {
    test('parse then format is stable', () {
      expect(formatServerDay(parseServerDay('2026-10-05')), '2026-10-05');
    });

    test('midnight and grace boundary days differ by one', () {
      final DateTime lateNight = DateTime(2026, 10, 1, 2, 30);
      final DateTime morning = DateTime(2026, 10, 1, 3, 30);
      // Same calendar day before and after the 03:00 grace cutoff.
      expect(lateNight.day, morning.day);
      expect(
        DateTime.utc(lateNight.year, lateNight.month, lateNight.day),
        DateTime.utc(2026, 10, 1),
      );
    });
  });
}
