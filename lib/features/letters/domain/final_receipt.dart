// Final Receipt calculations: promised vs kept, kept rate, top excuse.
// Letter bodies and excuse free texts are never included: the shared image
// shows aggregates only, no private notes.

import '../../../core/utils/streak_logic.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import 'letter_models.dart';

class FinalReceiptStats {
  const FinalReceiptStats({
    required this.promised,
    required this.kept,
    required this.keptRate,
    required this.longestStreak,
    required this.topExcuse,
    required this.topExcuseCount,
    required this.dayOneLetter,
  });

  final int promised;
  final int kept;
  final double keptRate;
  final int longestStreak;
  final String? topExcuse;
  final int topExcuseCount;
  final LetterEntry? dayOneLetter;
}

/// Computes the receipt from ledger rows up to and including [serverToday].
/// Paused days are skipped; future (promised) days do not count yet.
FinalReceiptStats computeFinalReceipt({
  required List<LedgerEntry> ledger,
  required List<Excuse> excuses,
  required List<LetterEntry> letters,
  required DateTime serverToday,
  required ContractMode mode,
}) {
  final DateTime today = DateTime.utc(
    serverToday.year,
    serverToday.month,
    serverToday.day,
  );
  final Map<DateTime, List<LedgerEntry>> byDay =
      <DateTime, List<LedgerEntry>>{};
  for (final LedgerEntry entry in ledger) {
    if (entry.day.isAfter(today)) {
      continue;
    }
    byDay.putIfAbsent(entry.day, () => <LedgerEntry>[]).add(entry);
  }
  final List<DateTime> days = byDay.keys.toList()..sort();
  int promised = 0;
  int kept = 0;
  final List<DailyStreakInput> walk = <DailyStreakInput>[];
  for (final DateTime day in days) {
    final List<LedgerEntry> rows = byDay[day]!;
    if (rows.any((LedgerEntry e) => e.isPaused)) {
      walk.add(const DailyStreakInput(allDone: false, isPaused: true));
      continue;
    }
    if (rows.isEmpty) {
      continue;
    }
    promised += rows.length;
    final int done = rows.where((LedgerEntry e) => e.done == true).length;
    kept += done;
    walk.add(DailyStreakInput(allDone: done == rows.length));
  }
  final Map<String, int> excuseCounts = <String, int>{};
  for (final Excuse e in excuses) {
    excuseCounts[e.reason.name] = (excuseCounts[e.reason.name] ?? 0) + 1;
  }
  String? top;
  int topCount = 0;
  for (final MapEntry<String, int> entry in excuseCounts.entries) {
    if (entry.value > topCount) {
      top = entry.key;
      topCount = entry.value;
    }
  }
  LetterEntry? dayOne;
  for (final LetterEntry letter in letters) {
    if (letter.unlockDayNumber == 0) {
      dayOne = letter;
    }
  }
  return FinalReceiptStats(
    promised: promised,
    kept: kept,
    keptRate: promised == 0 ? 0 : kept / promised,
    longestStreak: StreakLogic.longestStreak(daysOldestFirst: walk, mode: mode),
    topExcuse: top,
    topExcuseCount: topCount,
    dayOneLetter: dayOne,
  );
}

/// Share-safe one-line summary (no letter text, no free-text notes).
String receiptShareText({
  required int promised,
  required int kept,
  required int longestStreak,
}) {
  final int percent = promised == 0 ? 0 : ((kept / promised) * 100).round();
  return 'My 90-day receipt: $kept of $promised kept ($percent%). '
      'Longest streak: $longestStreak days.';
}
