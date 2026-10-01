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
}
