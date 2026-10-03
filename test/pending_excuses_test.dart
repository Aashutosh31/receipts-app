import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/excuse/domain/excuse_models.dart';

void main() {
  final DateTime today = DateTime.utc(2026, 10, 5);

  List<({String commitmentId, String title, DateTime day})> missed(
    List<DateTime> days,
  ) {
    return days
        .map((DateTime d) => (commitmentId: 'c1', title: 'Run', day: d))
        .toList();
  }

  group('pendingExcuses', () {
    test('yesterday and day-before count', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[
          DateTime.utc(2026, 10, 4),
          DateTime.utc(2026, 10, 3),
        ]),
        filed: const <Excuse>[],
        serverToday: today,
      );
      expect(result, hasLength(2));
    });

    test('today is not a miss yet', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 5)]),
        filed: const <Excuse>[],
        serverToday: today,
      );
      expect(result, isEmpty);
    });

    test('older than 2 days is out of the window', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 2)]),
        filed: const <Excuse>[],
        serverToday: today,
      );
      expect(result, isEmpty);
    });

    test('filed excuses are skipped', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
        filed: <Excuse>[
          Excuse(
            id: 'e1',
            commitmentId: 'c1',
            day: DateTime.utc(2026, 10, 4),
            reason: ExcuseReason.tired,
          ),
        ],
        serverToday: today,
      );
      expect(result, isEmpty);
    });

    test('results come back oldest first', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[
          DateTime.utc(2026, 10, 4),
          DateTime.utc(2026, 10, 3),
        ]),
        filed: const <Excuse>[],
        serverToday: today,
      );
      expect(result.first.day, DateTime.utc(2026, 10, 3));
    });
  });

  group('server-date round trip (regression: non-UTC devices)', () {
    // The server sends bare YYYY-MM-DD strings. Excuse.fromMap must parse
    // them as UTC midnight: DateTime.parse on a bare date yields LOCAL
    // midnight, and .toUtc() then shifts the calendar day on non-UTC
    // devices, so filed excuses never matched pending misses and the
    // sheet re-prompted forever. These tests are meaningful under a
    // non-UTC TZ (CI runs Asia/Kolkata); see .github/workflows/ci.yml.
    Excuse filedExcuse(String day) {
      return Excuse.fromMap(<String, dynamic>{
        'id': 'e-$day',
        'commitment_id': 'c1',
        'day': day,
        'reason': 'tired',
        'free_text': null,
      });
    }

    test('fromMap parses a bare server date as UTC midnight', () {
      final Excuse excuse = filedExcuse('2026-10-04');
      expect(excuse.day, DateTime.utc(2026, 10, 4));
      expect(excuse.day.isUtc, isTrue);
    });

    test('excuse for day 1 removes day 1 from pending (exact bug repro)', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
        filed: <Excuse>[filedExcuse('2026-10-04')],
        serverToday: today,
      );
      expect(result, isEmpty);
    });

    test('excuse for day 1 leaves day 2 still pending', () {
      final List<PendingExcuse> result = pendingExcuses(
        missed: missed(<DateTime>[
          DateTime.utc(2026, 10, 4),
          DateTime.utc(2026, 10, 3),
        ]),
        filed: <Excuse>[filedExcuse('2026-10-04')],
        serverToday: today,
      );
      expect(result.map((PendingExcuse p) => p.day), <DateTime>[
        DateTime.utc(2026, 10, 3),
      ]);
    });

    test('two different days can both carry excuses', () {
      final List<Excuse> filed = <Excuse>[
        filedExcuse('2026-10-04'),
        filedExcuse('2026-10-03'),
      ];
      expect(
        pendingExcuses(
          missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
          filed: filed,
          serverToday: today,
        ),
        isEmpty,
      );
      expect(
        pendingExcuses(
          missed: missed(<DateTime>[DateTime.utc(2026, 10, 3)]),
          filed: filed,
          serverToday: today,
        ),
        isEmpty,
      );
    });

    test('filed pair never reappears, so resubmission is impossible', () {
      // The pending queue is the only path to the excuse sheet. A filed
      // (commitment, day) pair must never be yielded again.
      final List<Excuse> filed = <Excuse>[filedExcuse('2026-10-04')];
      for (int i = 0; i < 3; i++) {
        expect(
          pendingExcuses(
            missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
            filed: filed,
            serverToday: today,
          ),
          isEmpty,
        );
      }
    });

    test('just-submitted excuse disappears from pending immediately', () {
      // Simulates the provider refresh right after a successful submit:
      // the filed list now contains the new row.
      final List<PendingExcuse> before = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
        filed: const <Excuse>[],
        serverToday: today,
      );
      expect(before, hasLength(1));
      final List<PendingExcuse> after = pendingExcuses(
        missed: missed(<DateTime>[DateTime.utc(2026, 10, 4)]),
        filed: <Excuse>[filedExcuse('2026-10-04')],
        serverToday: today,
      );
      expect(after, isEmpty);
    });
  });
}
