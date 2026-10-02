import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/excuse/domain/excuse_models.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';
import 'package:receipts/features/reminders/domain/message_engine.dart';
import 'package:receipts/features/reminders/domain/reminder_plan.dart';
import 'package:timezone/data/latest.dart' as tzdb;
import 'package:timezone/timezone.dart' as tz;

LedgerEntry _row({
  required DateTime day,
  required String status,
  bool? done,
  bool paused = false,
}) {
  return LedgerEntry(
    day: day,
    commitmentId: 'c1',
    commitmentTitle: 'Run',
    status: status,
    done: done,
    isPaused: paused,
  );
}

void main() {
  group('parseTargetTime', () {
    test('valid times parse', () {
      expect(parseTargetTime('06:30'), (hour: 6, minute: 30));
      expect(parseTargetTime('00:00'), (hour: 0, minute: 0));
      expect(parseTargetTime('23:59'), (hour: 23, minute: 59));
    });

    test('invalid times are null', () {
      expect(parseTargetTime(''), isNull);
      expect(parseTargetTime('25:00'), isNull);
      expect(parseTargetTime('6:30'), isNull);
      expect(parseTargetTime('06:60'), isNull);
      expect(parseTargetTime('nope'), isNull);
    });
  });

  group('reminderNotificationId', () {
    final DateTime day = DateTime.utc(2026, 10, 5);

    test('stable across calls', () {
      expect(
        reminderNotificationId(day, 'c1', ReminderKind.upcoming),
        reminderNotificationId(day, 'c1', ReminderKind.upcoming),
      );
    });

    test('unique per kind, day, and commitment', () {
      final Set<int> ids = <int>{
        reminderNotificationId(day, 'c1', ReminderKind.upcoming),
        reminderNotificationId(day, 'c1', ReminderKind.followUp),
        reminderNotificationId(day, 'c1', ReminderKind.lastCall),
        reminderNotificationId(
          DateTime.utc(2026, 10, 6),
          'c1',
          ReminderKind.upcoming,
        ),
        reminderNotificationId(day, 'c2', ReminderKind.upcoming),
      };
      expect(ids, hasLength(5));
    });

    test('fits Android int range', () {
      for (int i = 0; i < 50; i++) {
        final int id = reminderNotificationId(
          DateTime.utc(2026, 10, i + 1),
          'commitment-$i',
          ReminderKind.values[i % 3],
        );
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(2000000000));
      }
    });
  });

  group('shiftForQuietHours', () {
    const QuietHours quiet = QuietHours(
      startMinutes: 22 * 60,
      endMinutes: 7 * 60,
    );

    test('outside quiet hours is unchanged', () {
      final DateTime fire = DateTime(2026, 10, 5, 18, 0);
      expect(shiftForQuietHours(fire, quiet), fire);
    });

    test('late night rolls to next morning', () {
      final DateTime shifted = shiftForQuietHours(
        DateTime(2026, 10, 5, 23, 30),
        quiet,
      );
      expect(shifted, DateTime(2026, 10, 6, 7, 0));
    });

    test('early morning moves to the same morning', () {
      final DateTime shifted = shiftForQuietHours(
        DateTime(2026, 10, 5, 6, 30),
        quiet,
      );
      expect(shifted, DateTime(2026, 10, 5, 7, 0));
    });

    test('disabled quiet hours never shift', () {
      const QuietHours off = QuietHours(startMinutes: 0, endMinutes: 0);
      final DateTime fire = DateTime(2026, 10, 5, 3, 0);
      expect(shiftForQuietHours(fire, off), fire);
    });
  });

  group('consecutiveMisses', () {
    final DateTime today = DateTime.utc(2026, 10, 5);

    test('counts the trailing run', () {
      final int misses = consecutiveMisses(
        <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 5), status: 'missed', done: false),
          _row(day: DateTime.utc(2026, 10, 4), status: 'missed', done: false),
          _row(day: DateTime.utc(2026, 10, 3), status: 'done', done: true),
        ],
        'c1',
        today,
      );
      expect(misses, 2);
    });

    test('paused days are skipped, future ignored', () {
      final int misses = consecutiveMisses(
        <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 6), status: 'promised'),
          _row(day: DateTime.utc(2026, 10, 5), status: 'paused', paused: true),
          _row(day: DateTime.utc(2026, 10, 4), status: 'missed', done: false),
        ],
        'c1',
        today,
      );
      expect(misses, 1);
    });
  });

  group('lastExcuseFor', () {
    test('returns the most recent reason', () {
      final String? reason = lastExcuseFor(<Excuse>[
        Excuse(
          id: 'e1',
          commitmentId: 'c1',
          day: DateTime.utc(2026, 10, 3),
          reason: ExcuseReason.busy,
        ),
        Excuse(
          id: 'e2',
          commitmentId: 'c1',
          day: DateTime.utc(2026, 10, 4),
          reason: ExcuseReason.tired,
        ),
      ], 'c1');
      expect(reason, 'tired');
    });

    test('null when nothing filed', () {
      expect(lastExcuseFor(const <Excuse>[], 'c1'), isNull);
    });
  });

  group('planWeek', () {
    test('target plus follow-up plus last call per day', () {
      final DateTime today = DateTime.utc(2026, 10, 5);
      const QuietHours noQuiet = QuietHours(startMinutes: 0, endMinutes: 0);
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 12, 30),
        serverToday: today,
        commitments: <CommitmentScheduleInput>[
          CommitmentScheduleInput(
            id: 'c1',
            title: 'Run',
            targetTime: '06:30',
            enabled: true,
            born: DateTime.utc(2026, 10, 1),
          ),
        ],
        doneDaysByCommitment: const <String, Set<DateTime>>{},
        pausedDays: const <DateTime>{},
        quiet: noQuiet,
      );
      // 7 days x (upcoming + followUp + lastCall) = 21.
      expect(plan, hasLength(21));
      final PlannedReminder first = plan.first;
      expect(first.kind, ReminderKind.upcoming);
      expect(first.fireAtLocal, DateTime(2026, 10, 5, 6, 30));
      expect(plan[1].kind, ReminderKind.followUp);
      expect(plan[1].fireAtLocal, DateTime(2026, 10, 5, 7, 0));
      expect(plan[2].kind, ReminderKind.lastCall);
      expect(plan[2].fireAtLocal, DateTime(2026, 10, 5, 21, 0));
    });

    test('default quiet hours shift early targets to 07:00', () {
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 10, 6),
        serverToday: DateTime.utc(2026, 10, 5),
        commitments: <CommitmentScheduleInput>[
          CommitmentScheduleInput(
            id: 'c1',
            title: 'Run',
            targetTime: '06:30',
            enabled: true,
            born: DateTime.utc(2026, 10, 1),
          ),
        ],
        doneDaysByCommitment: const <String, Set<DateTime>>{},
        pausedDays: const <DateTime>{},
      );
      expect(plan.first.fireAtLocal, DateTime(2026, 10, 5, 7, 0));
    });

    test('done days skip the follow-up', () {
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 10, 10),
        serverToday: DateTime.utc(2026, 10, 5),
        commitments: <CommitmentScheduleInput>[
          CommitmentScheduleInput(
            id: 'c1',
            title: 'Run',
            targetTime: '06:30',
            enabled: true,
            born: DateTime.utc(2026, 10, 1),
          ),
        ],
        doneDaysByCommitment: <String, Set<DateTime>>{
          'c1': <DateTime>{DateTime.utc(2026, 10, 5)},
        },
        pausedDays: const <DateTime>{},
      );
      final Iterable<PlannedReminder> followUps = plan.where(
        (PlannedReminder p) =>
            p.kind == ReminderKind.followUp &&
            p.day == DateTime.utc(2026, 10, 5),
      );
      expect(followUps, isEmpty);
    });

    test('paused days and disabled commitments are skipped', () {
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 10, 10),
        serverToday: DateTime.utc(2026, 10, 5),
        commitments: <CommitmentScheduleInput>[
          CommitmentScheduleInput(
            id: 'c1',
            title: 'Run',
            targetTime: '06:30',
            enabled: false,
            born: DateTime.utc(2026, 10, 1),
          ),
          CommitmentScheduleInput(
            id: 'c2',
            title: 'Read',
            targetTime: null,
            enabled: true,
            born: DateTime.utc(2026, 10, 1),
          ),
        ],
        doneDaysByCommitment: const <String, Set<DateTime>>{},
        pausedDays: <DateTime>{DateTime.utc(2026, 10, 5)},
      );
      // Day 1 paused; remaining 6 days carry only last calls (no timed
      // commitments: one disabled, one without a target time).
      expect(plan, hasLength(6));
      expect(
        plan.every((PlannedReminder p) => p.kind == ReminderKind.lastCall),
        isTrue,
      );
    });

    test('never exceeds the platform cap', () {
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 12, 30),
        serverToday: DateTime.utc(2026, 10, 5),
        commitments: <CommitmentScheduleInput>[
          for (int i = 0; i < 5; i++)
            CommitmentScheduleInput(
              id: 'c$i',
              title: 'Habit $i',
              targetTime: '07:00',
              enabled: true,
              born: DateTime.utc(2026, 10, 1),
            ),
        ],
        doneDaysByCommitment: const <String, Set<DateTime>>{},
        pausedDays: const <DateTime>{},
      );
      expect(plan.length, lessThanOrEqualTo(maxScheduledNotifications));
      // Five timed commitments fill 11 slots a day; the cap stops the
      // sixth day partway, so the window packs tightly under the limit.
      expect(plan.length, greaterThan(55));
    });

    test('midnight target rolls the follow-up to the next day', () {
      final List<PlannedReminder> plan = planWeek(
        contractStart: DateTime.utc(2026, 10, 1),
        contractEnd: DateTime.utc(2026, 10, 10),
        serverToday: DateTime.utc(2026, 10, 5),
        commitments: <CommitmentScheduleInput>[
          CommitmentScheduleInput(
            id: 'c1',
            title: 'Meditate',
            targetTime: '23:50',
            enabled: true,
            born: DateTime.utc(2026, 10, 1),
          ),
        ],
        doneDaysByCommitment: const <String, Set<DateTime>>{},
        pausedDays: const <DateTime>{},
        quiet: const QuietHours(startMinutes: 0, endMinutes: 0),
      );
      final PlannedReminder followUp = plan.firstWhere(
        (PlannedReminder p) => p.kind == ReminderKind.followUp,
      );
      expect(followUp.fireAtLocal, DateTime(2026, 10, 6, 0, 20));
    });
  });

  group('timezone edge cases', () {
    test('nonexistent local time does not throw', () {
      tzdb.initializeTimeZones();
      final tz.Location newYork = tz.getLocation('America/New_York');
      // 2026-03-08 02:30 never happens in New York (spring forward).
      final tz.TZDateTime resolved = tz.TZDateTime(newYork, 2026, 3, 8, 2, 30);
      // The database resolves it instead of throwing; scheduling uses the
      // resolved instant, so reminders survive DST transitions.
      expect(resolved.timeZoneOffset.inHours, anyOf([-5, -4]));
    });
  });
}
