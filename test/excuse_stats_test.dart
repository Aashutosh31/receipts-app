import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/excuse/domain/excuse_models.dart';
import 'package:receipts/features/insights/domain/excuse_stats.dart';

Excuse _excuse({
  required String id,
  required DateTime day,
  required ExcuseReason reason,
  String commitment = 'c1',
}) {
  return Excuse(id: id, commitmentId: commitment, day: day, reason: reason);
}

void main() {
  group('computeExcuseStats', () {
    test('counts by reason with top first', () {
      final ExcuseStats stats = computeExcuseStats(<Excuse>[
        _excuse(
          id: 'e1',
          day: DateTime.utc(2026, 9, 7),
          reason: ExcuseReason.tired,
        ),
        _excuse(
          id: 'e2',
          day: DateTime.utc(2026, 9, 8),
          reason: ExcuseReason.busy,
        ),
        _excuse(
          id: 'e3',
          day: DateTime.utc(2026, 9, 9),
          reason: ExcuseReason.tired,
        ),
      ]);
      expect(stats.total, 3);
      expect(stats.byReason, {'tired': 2, 'busy': 1});
      expect(stats.topReason, 'tired');
      expect(stats.topCount, 2);
    });

    test('counts by weekday using Monday=1', () {
      // 2026-09-07 is a Monday.
      final ExcuseStats stats = computeExcuseStats(<Excuse>[
        _excuse(
          id: 'e1',
          day: DateTime.utc(2026, 9, 7),
          reason: ExcuseReason.tired,
        ),
        _excuse(
          id: 'e2',
          day: DateTime.utc(2026, 9, 9),
          reason: ExcuseReason.tired,
        ),
      ]);
      expect(stats.byWeekday[1], 1);
      expect(stats.byWeekday[3], 1);
      expect(
        stats.peakWeekdayFor('tired', <Excuse>[
          _excuse(
            id: 'e1',
            day: DateTime.utc(2026, 9, 7),
            reason: ExcuseReason.tired,
          ),
        ]),
        1,
      );
    });

    test('counts by commitment title, not id', () {
      final ExcuseStats stats = computeExcuseStats(
        <Excuse>[
          _excuse(
            id: 'e1',
            day: DateTime.utc(2026, 9, 7),
            reason: ExcuseReason.forgot,
            commitment: 'c9',
          ),
        ],
        commitmentTitles: const <String, String>{'c9': 'Run 20 minutes'},
      );
      expect(stats.byCommitment, {'Run 20 minutes': 1});
    });

    test('weekly trend buckets Monday to Monday', () {
      final ExcuseStats stats = computeExcuseStats(<Excuse>[
        _excuse(
          id: 'e1',
          day: DateTime.utc(2026, 9, 8),
          reason: ExcuseReason.busy,
        ),
        _excuse(
          id: 'e2',
          day: DateTime.utc(2026, 9, 16),
          reason: ExcuseReason.busy,
        ),
      ], referenceToday: DateTime.utc(2026, 9, 20));
      expect(stats.weeklyTrend.map((WeekBucket b) => b.count), [1, 1]);
      expect(stats.weeklyTrend.first.weekStart.weekday, 1);
      expect(stats.weeklyTrend.first.label, 'Sep 7');
    });

    test('empty input yields empty stats', () {
      final ExcuseStats stats = computeExcuseStats(const <Excuse>[]);
      expect(stats.total, 0);
      expect(stats.topReason, isNull);
      expect(stats.topCount, 0);
      expect(stats.weeklyTrend, isEmpty);
    });
  });

  group('insightLine', () {
    test('weekday concentration example', () {
      final List<Excuse> excuses = <Excuse>[
        for (int i = 0; i < 8; i++)
          _excuse(
            id: 'm$i',
            day: DateTime.utc(2026, 9, 7 + i * 7),
            reason: ExcuseReason.tired,
          ),
        for (int i = 0; i < 3; i++)
          _excuse(
            id: 't$i',
            day: DateTime.utc(2026, 9, 9 + i * 7),
            reason: ExcuseReason.tired,
          ),
      ];
      final ExcuseStats stats = computeExcuseStats(excuses);
      expect(
        insightLine(stats, excuses),
        'Your #1 excuse is \'tired\' (11 times). '
        '8 of them were on Mondays.',
      );
    });

    test('commitment concentration fallback', () {
      final List<Excuse> excuses = <Excuse>[
        _excuse(
          id: 'e1',
          day: DateTime.utc(2026, 9, 7),
          reason: ExcuseReason.busy,
          commitment: 'c1',
        ),
        _excuse(
          id: 'e2',
          day: DateTime.utc(2026, 9, 9),
          reason: ExcuseReason.busy,
          commitment: 'c1',
        ),
        _excuse(
          id: 'e3',
          day: DateTime.utc(2026, 9, 11),
          reason: ExcuseReason.busy,
          commitment: 'c1',
        ),
        _excuse(
          id: 'e4',
          day: DateTime.utc(2026, 9, 14),
          reason: ExcuseReason.forgot,
          commitment: 'c2',
        ),
      ];
      final ExcuseStats stats = computeExcuseStats(
        excuses,
        commitmentTitles: const <String, String>{
          'c1': 'Run 20 minutes',
          'c2': 'Read 10 pages',
        },
      );
      expect(
        insightLine(stats, excuses),
        'Your #1 excuse is \'busy\' (3 times). '
        'Most often on \'Run 20 minutes\'.',
      );
    });

    test('plain fallback and empty state', () {
      final ExcuseStats one = computeExcuseStats(<Excuse>[
        _excuse(
          id: 'e1',
          day: DateTime.utc(2026, 9, 7),
          reason: ExcuseReason.other,
        ),
      ]);
      expect(
        insightLine(one, <Excuse>[
          _excuse(
            id: 'e1',
            day: DateTime.utc(2026, 9, 7),
            reason: ExcuseReason.other,
          ),
        ]),
        'Your #1 excuse is \'other\' (1 time).',
      );
      expect(
        insightLine(computeExcuseStats(const <Excuse>[]), const <Excuse>[]),
        contains('No excuses on record'),
      );
    });
  });
}
