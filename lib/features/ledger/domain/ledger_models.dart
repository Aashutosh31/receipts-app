// Pure ledger domain: models + view helpers mirroring SQL get_ledger and
// get_streak. Server dates (from the RPCs) are the input; no device clock.

/// Day-level status shown in the Ledger grid. Priority when mixed:
/// paused > upcoming > kept > missed.
enum DayStatus { kept, missed, paused, upcoming }

/// One row of public.get_ledger(p_contract_id).
class LedgerEntry {
  const LedgerEntry({
    required this.day,
    required this.commitmentId,
    required this.commitmentTitle,
    required this.status,
    required this.done,
    required this.isPaused,
  });

  /// Calendar day at UTC midnight (server `date` parses without a zone).
  final DateTime day;
  final String commitmentId;
  final String commitmentTitle;

  /// One of kept-source values: done | missed | paused | promised.
  final String status;
  final bool? done;
  final bool isPaused;

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      day: parseServerDay(map['day'] as String),
      commitmentId: map['commitment_id'] as String,
      commitmentTitle: map['commitment_title'] as String,
      status: map['status'] as String,
      done: map['done'] as bool?,
      isPaused: map['is_paused'] as bool? ?? false,
    );
  }
}

/// Single row of public.get_streak(p_contract_id).
class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.recoveriesUsed,
    required this.mode,
    required this.today,
  });

  final int currentStreak;
  final int recoveriesUsed;
  final String mode;

  /// Server-computed "today" in the user's timezone. Source of truth for
  /// day number, Today screen, and excuse windows.
  final DateTime today;

  factory StreakInfo.fromMap(Map<String, dynamic> map) {
    return StreakInfo(
      currentStreak: (map['current_streak'] as num).toInt(),
      recoveriesUsed: (map['recoveries_used'] as num).toInt(),
      mode: map['mode'] as String,
      today: parseServerDay(map['today'] as String),
    );
  }
}

/// One Ledger grid cell: a calendar day rolled up across commitments.
class LedgerDay {
  const LedgerDay({
    required this.day,
    required this.status,
    required this.doneCount,
    required this.totalCount,
  });

  final DateTime day;
  final DayStatus status;
  final int doneCount;
  final int totalCount;
}

/// Rolls ledger rows up to one [LedgerDay] per calendar day. Days with no
/// rows (e.g. before a commitment existed) are neutral `upcoming` cells.
List<LedgerDay> summarizeLedgerDays(
  List<LedgerEntry> entries,
  DateTime serverToday,
) {
  final Map<DateTime, List<LedgerEntry>> byDay =
      <DateTime, List<LedgerEntry>>{};
  for (final LedgerEntry entry in entries) {
    byDay.putIfAbsent(entry.day, () => <LedgerEntry>[]).add(entry);
  }
  final List<DateTime> days = byDay.keys.toList()..sort();
  return days.map((DateTime day) {
    final List<LedgerEntry> rows = byDay[day]!;
    final bool paused = rows.any((LedgerEntry e) => e.isPaused);
    final int done = rows.where((LedgerEntry e) => e.done == true).length;
    final DayStatus status;
    if (paused) {
      status = DayStatus.paused;
    } else if (day.isAfter(serverToday)) {
      status = DayStatus.upcoming;
    } else if (rows.isNotEmpty && done == rows.length) {
      status = DayStatus.kept;
    } else {
      status = DayStatus.missed;
    }
    return LedgerDay(
      day: day,
      status: status,
      doneCount: done,
      totalCount: rows.length,
    );
  }).toList();
}

/// 1-based day number inside the contract. Clamped to >= 1.
int dayNumber(DateTime startDate, DateTime serverToday) {
  final DateTime start = DateTime.utc(
    startDate.year,
    startDate.month,
    startDate.day,
  );
  final DateTime today = DateTime.utc(
    serverToday.year,
    serverToday.month,
    serverToday.day,
  );
  final int number = today.difference(start).inDays + 1;
  return number < 1 ? 1 : number;
}

/// Parses a server `date` (YYYY-MM-DD) to UTC midnight.
DateTime parseServerDay(String value) {
  final List<String> parts = value.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Formats a day back to YYYY-MM-DD for inserts and RPC params.
String formatServerDay(DateTime day) {
  final String month = day.month.toString().padLeft(2, '0');
  final String date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

/// Honest status line for the Today screen. Direct, never cruel.
String todayStatusLine({
  required int dayNumber,
  int totalDays = 90,
  required int doneCount,
  required int totalCount,
  required int streak,
  required bool isPaused,
}) {
  if (isPaused) {
    return 'Day $dayNumber of $totalDays · Paused — rest. '
        'The streak ($streak) waits for you.';
  }
  if (totalCount == 0) {
    return 'Day $dayNumber of $totalDays · Nothing promised yet.';
  }
  if (doneCount >= totalCount) {
    return 'Day $dayNumber of $totalDays · All $totalCount done. '
        'Streak $streak. Receipt kept.';
  }
  final int left = totalCount - doneCount;
  if (doneCount == 0) {
    return 'Day $dayNumber of $totalDays · Nothing logged yet. '
        'Streak $streak. The day is still yours.';
  }
  return 'Day $dayNumber of $totalDays · $doneCount of $totalCount done — '
      '$left left. Streak $streak. Finish it.';
}
