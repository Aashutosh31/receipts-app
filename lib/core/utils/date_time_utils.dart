/// Date/time helpers for Receipts.
///
/// Truth about time comes from the SERVER (now() in Postgres), never the
/// device clock, for anything that locks, unlocks, or dates a record.
/// These pure-Dart helpers mirror the SQL grace-window rules so they can be
/// unit-tested locally. The SQL triggers in /supabase/migrations remain
/// authoritative.
class DateTimeUtils {
  /// Grace window: a check-in for [targetDay] is accepted when the server
  /// local time is still on [targetDay], or on the next calendar day before
  /// 03:00 local. This lets late-night check-ins count without allowing
  /// history backfill.
  ///
  /// [serverNowLocal] must already be converted to the user's profile
  /// timezone on the caller side (SQL does this with AT TIME ZONE).
  /// Both [serverNowLocal] and [targetDay] are compared by calendar day only.
  static bool canCheckInForDay({
    required DateTime serverNowLocal,
    required DateTime targetDay,
  }) {
    final DateTime today = DateTime(
      serverNowLocal.year,
      serverNowLocal.month,
      serverNowLocal.day,
    );
    final DateTime target = DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
    );
    if (target == today) {
      return true;
    }
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    if (target == yesterday && serverNowLocal.hour < 3) {
      return true;
    }
    return false;
  }

  /// Returns true when [targetDay] is strictly before the effective local day
  /// (i.e. a backfill attempt outside the grace window).
  static bool isBackfill({
    required DateTime serverNowLocal,
    required DateTime targetDay,
  }) {
    return !canCheckInForDay(
      serverNowLocal: serverNowLocal,
      targetDay: targetDay,
    );
  }

  /// Excuses are allowed only for past days with no done check-in, within
  /// 48 hours of the missed day (measured from start of [missedDay] + 48h).
  static bool canFileExcuse({
    required DateTime serverNowUtc,
    required DateTime missedDayUtcMidnight,
  }) {
    if (serverNowUtc.isBefore(missedDayUtcMidnight)) {
      return false;
    }
    final Duration elapsed = serverNowUtc.difference(missedDayUtcMidnight);
    return elapsed <= const Duration(hours: 48);
  }

  /// Strips a DateTime to its calendar day (local).
  static DateTime dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
