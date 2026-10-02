// Streak calculation mirroring SQL get_streak(contract_id).
//
// Rules (AGENTS.md product):
// - Hard Mode: any miss resets the streak to zero.
// - Kind Mode: up to [maxRecoveries] missed days per contract are tolerated
//   without resetting; the third (and beyond) miss resets.
// - Sick/Injury pauses never break the streak and are skipped when counting.

enum ContractMode { hard, kind }

class DailyStreakInput {
  const DailyStreakInput({required this.allDone, this.isPaused = false});

  final bool allDone;
  final bool isPaused;
}

class StreakResult {
  const StreakResult({
    required this.currentStreak,
    required this.recoveriesUsed,
  });

  final int currentStreak;
  final int recoveriesUsed;
}

class StreakLogic {
  static StreakResult calculateCurrentStreak({
    required List<DailyStreakInput> daysOldestFirst,
    required ContractMode mode,
    int maxRecoveries = 2,
  }) {
    int streak = 0;
    int recoveriesUsed = 0;

    // Walk chronologically: recovery budget is consumed by the earliest
    // misses first. A miss with budget left counts toward the streak; a miss
    // with no budget left resets the streak to zero.
    for (final DailyStreakInput day in daysOldestFirst) {
      if (day.isPaused) {
        continue;
      }
      if (day.allDone) {
        streak += 1;
        continue;
      }
      // Miss day.
      if (mode == ContractMode.kind && recoveriesUsed < maxRecoveries) {
        recoveriesUsed += 1;
        streak += 1;
      } else {
        streak = 0;
      }
    }

    return StreakResult(
      currentStreak: streak,
      recoveriesUsed: mode == ContractMode.kind ? recoveriesUsed : 0,
    );
  }

  /// Longest streak over the same walk as [calculateCurrentStreak]: the
  /// recovery budget is consumed chronologically across the whole history,
  /// and the maximum running value is reported.
  static int longestStreak({
    required List<DailyStreakInput> daysOldestFirst,
    required ContractMode mode,
    int maxRecoveries = 2,
  }) {
    int streak = 0;
    int best = 0;
    int recoveriesUsed = 0;
    for (final DailyStreakInput day in daysOldestFirst) {
      if (day.isPaused) {
        continue;
      }
      if (day.allDone) {
        streak += 1;
      } else if (mode == ContractMode.kind && recoveriesUsed < maxRecoveries) {
        recoveriesUsed += 1;
        streak += 1;
      } else {
        streak = 0;
      }
      if (streak > best) {
        best = streak;
      }
    }
    return best;
  }
}
