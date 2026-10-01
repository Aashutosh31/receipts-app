/// Ledger status mapping mirroring SQL get_ledger(contract_id).
///
/// Each day per commitment resolves to exactly one of:
/// promised (future), done, missed (past, no check-in, not paused),
/// paused (sick/injury cover).
enum CommitmentDayStatus { promised, done, missed, paused }

class LedgerLogic {
  static CommitmentDayStatus statusForDay({
    required bool isFuture,
    required bool isPaused,
    required bool? done,
  }) {
    if (isPaused) {
      return CommitmentDayStatus.paused;
    }
    if (isFuture) {
      return CommitmentDayStatus.promised;
    }
    if (done == true) {
      return CommitmentDayStatus.done;
    }
    return CommitmentDayStatus.missed;
  }

  /// A day counts as complete only when every active commitment is done
  /// or the day is paused.
  static bool isDayComplete({
    required List<bool?> doneByCommitment,
    required bool isPaused,
  }) {
    if (isPaused) {
      return true;
    }
    if (doneByCommitment.isEmpty) {
      return false;
    }
    return doneByCommitment.every((bool? done) => done == true);
  }
}
