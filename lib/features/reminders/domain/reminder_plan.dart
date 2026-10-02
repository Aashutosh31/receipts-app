// Pure reminder scheduling calculations. All fire times are device-local
// wall-clock DateTimes; the notification service converts them to TZDateTime
// in the device location before handing them to the plugin.

import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import 'message_engine.dart';

/// Evening "last call" in local wall-clock time.
const int lastCallHour = 21;
const int lastCallMinute = 0;

/// Follow-up delay after a target time when nothing is logged.
const Duration followUpDelay = Duration(minutes: 30);

/// Hard cap on scheduled notifications (iOS keeps only the 64 most recently
/// set pending requests; staying at 60 leaves headroom).
/// See: https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
const int maxScheduledNotifications = 60;

/// Quiet hours as minutes since midnight. Overnight ranges (e.g. 22:00-07:00)
/// wrap past midnight.
class QuietHours {
  const QuietHours({required this.startMinutes, required this.endMinutes});

  /// Default 22:00-07:00.
  static const QuietHours def = QuietHours(
    startMinutes: 22 * 60,
    endMinutes: 7 * 60,
  );

  final int startMinutes;
  final int endMinutes;

  bool contains(int minutesSinceMidnight) {
    if (startMinutes == endMinutes) {
      return false;
    }
    if (startMinutes < endMinutes) {
      return minutesSinceMidnight >= startMinutes &&
          minutesSinceMidnight < endMinutes;
    }
    return minutesSinceMidnight >= startMinutes ||
        minutesSinceMidnight < endMinutes;
  }
}

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.day,
    required this.kind,
    this.commitmentId,
    required this.title,
    required this.fireAtLocal,
  });

  final int id;
  final DateTime day;
  final ReminderKind kind;
  final String? commitmentId;
  final String title;
  final DateTime fireAtLocal;
}

/// Stable FNV-1a hash (Dart's String.hashCode varies between runs, which
/// would break notification IDs and template picks across restarts).
int stableHash(String value) {
  int hash = 0x811C9DC5;
  for (int i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Deterministic notification id for (day, commitment, kind). Stable across
/// restarts so follow-ups can be cancelled when a check-in lands.
int reminderNotificationId(
  DateTime day,
  String commitmentKey,
  ReminderKind kind,
) {
  final String raw =
      '${day.year}-${day.month}-${day.day}|$commitmentKey|${kind.index}';
  return stableHash(raw) % 2000000000;
}

/// Parses HH:MM (24-hour) to (hour, minute), or null when invalid.
({int hour, int minute})? parseTargetTime(String value) {
  final RegExp pattern = RegExp(r'^([01][0-9]|2[0-3]):([0-5][0-9])$');
  final RegExpMatch? match = pattern.firstMatch(value.trim());
  if (match == null) {
    return null;
  }
  return (hour: int.parse(match.group(1)!), minute: int.parse(match.group(2)!));
}

/// Moves [fireAt] out of quiet hours to the quiet window's end. Overnight
/// windows roll into the next morning.
DateTime shiftForQuietHours(DateTime fireAt, QuietHours quiet) {
  final int minutes = fireAt.hour * 60 + fireAt.minute;
  if (!quiet.contains(minutes)) {
    return fireAt;
  }
  final int endHour = quiet.endMinutes ~/ 60;
  final int endMinute = quiet.endMinutes % 60;
  DateTime shifted = DateTime(
    fireAt.year,
    fireAt.month,
    fireAt.day,
    endHour,
    endMinute,
  );
  if (!shifted.isAfter(fireAt)) {
    shifted = shifted.add(const Duration(days: 1));
  }
  return shifted;
}

/// Trailing run of missed days for one commitment, skipping paused and
/// future days, stopping at the first done day.
int consecutiveMisses(
  List<LedgerEntry> entries,
  String commitmentId,
  DateTime serverToday,
) {
  final List<LedgerEntry> rows =
      entries
          .where(
            (LedgerEntry e) =>
                e.commitmentId == commitmentId && !e.day.isAfter(serverToday),
          )
          .toList()
        ..sort((LedgerEntry a, LedgerEntry b) => b.day.compareTo(a.day));
  int misses = 0;
  for (final LedgerEntry row in rows) {
    if (row.isPaused) {
      continue;
    }
    if (row.done == true || row.status == 'promised') {
      break;
    }
    misses += 1;
  }
  return misses;
}

/// Most recent excuse reason for a commitment, or null when none filed.
String? lastExcuseFor(List<Excuse> excuses, String commitmentId) {
  final List<Excuse> rows =
      excuses.where((Excuse e) => e.commitmentId == commitmentId).toList()
        ..sort((Excuse a, Excuse b) => b.day.compareTo(a.day));
  return rows.isEmpty ? null : rows.first.reason.name;
}

/// Input for one commitment's daily reminders.
class CommitmentScheduleInput {
  const CommitmentScheduleInput({
    required this.id,
    required this.title,
    this.targetTime,
    required this.enabled,
    required this.born,
    this.retired,
  });

  final String id;
  final String title;
  final String? targetTime;
  final bool enabled;
  final DateTime born;
  final DateTime? retired;

  bool activeOn(DateTime day) {
    if (day.isBefore(born)) {
      return false;
    }
    if (retired != null && !day.isBefore(retired!)) {
      return false;
    }
    return true;
  }
}

/// Builds up to [maxScheduledNotifications] reminders for the 7-day window
/// starting at [serverToday] (clamped to the contract range): per enabled
/// commitment with a target time a reminder at that time plus a +30 minute
/// follow-up (skipped when already done), plus one evening last call per day.
List<PlannedReminder> planWeek({
  required DateTime contractStart,
  required DateTime contractEnd,
  required DateTime serverToday,
  required List<CommitmentScheduleInput> commitments,
  required Map<String, Set<DateTime>> doneDaysByCommitment,
  required Set<DateTime> pausedDays,
  QuietHours quiet = QuietHours.def,
}) {
  final List<PlannedReminder> plan = <PlannedReminder>[];
  final DateTime today = DateTime(
    serverToday.year,
    serverToday.month,
    serverToday.day,
  );
  for (int offset = 0; offset < 7; offset++) {
    final DateTime day = today.add(Duration(days: offset));
    if (day.isBefore(contractStart) || day.isAfter(contractEnd)) {
      continue;
    }
    if (pausedDays.contains(day)) {
      continue;
    }
    for (final CommitmentScheduleInput c in commitments) {
      if (!c.enabled || !c.activeOn(day)) {
        continue;
      }
      final ({int hour, int minute})? target = c.targetTime == null
          ? null
          : parseTargetTime(c.targetTime!);
      if (target == null) {
        continue;
      }
      final bool done = doneDaysByCommitment[c.id]?.contains(day) ?? false;
      // Room check first so the platform cap is never exceeded.
      if (plan.length + (done ? 1 : 2) > maxScheduledNotifications) {
        return plan;
      }
      final DateTime atTarget = shiftForQuietHours(
        DateTime(day.year, day.month, day.day, target.hour, target.minute),
        quiet,
      );
      plan.add(
        PlannedReminder(
          id: reminderNotificationId(day, c.id, ReminderKind.upcoming),
          day: day,
          kind: ReminderKind.upcoming,
          commitmentId: c.id,
          title: c.title,
          fireAtLocal: atTarget,
        ),
      );
      if (!done) {
        final DateTime followUp = shiftForQuietHours(
          DateTime(
            day.year,
            day.month,
            day.day,
            target.hour,
            target.minute,
          ).add(followUpDelay),
          quiet,
        );
        plan.add(
          PlannedReminder(
            id: reminderNotificationId(day, c.id, ReminderKind.followUp),
            day: day,
            kind: ReminderKind.followUp,
            commitmentId: c.id,
            title: c.title,
            fireAtLocal: followUp,
          ),
        );
      }
      if (plan.length >= maxScheduledNotifications) {
        return plan;
      }
    }
    if (plan.length + 1 > maxScheduledNotifications) {
      return plan;
    }
    plan.add(
      PlannedReminder(
        id: reminderNotificationId(day, 'day', ReminderKind.lastCall),
        day: day,
        kind: ReminderKind.lastCall,
        title: 'Day review',
        fireAtLocal: shiftForQuietHours(
          DateTime(day.year, day.month, day.day, lastCallHour, lastCallMinute),
          quiet,
        ),
      ),
    );
  }
  return plan;
}
