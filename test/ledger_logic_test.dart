import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/utils/ledger_logic.dart';

void main() {
  group('LedgerLogic.statusForDay', () {
    test('paused wins over everything', () {
      expect(
        LedgerLogic.statusForDay(isFuture: true, isPaused: true, done: null),
        CommitmentDayStatus.paused,
      );
    });

    test('future day is promised', () {
      expect(
        LedgerLogic.statusForDay(isFuture: true, isPaused: false, done: null),
        CommitmentDayStatus.promised,
      );
    });

    test('done check-in is done', () {
      expect(
        LedgerLogic.statusForDay(isFuture: false, isPaused: false, done: true),
        CommitmentDayStatus.done,
      );
    });

    test('past day without done is missed', () {
      expect(
        LedgerLogic.statusForDay(isFuture: false, isPaused: false, done: false),
        CommitmentDayStatus.missed,
      );
      expect(
        LedgerLogic.statusForDay(isFuture: false, isPaused: false, done: null),
        CommitmentDayStatus.missed,
      );
    });
  });

  group('LedgerLogic.isDayComplete', () {
    test('paused day counts as complete', () {
      expect(
        LedgerLogic.isDayComplete(
          doneByCommitment: const [false],
          isPaused: true,
        ),
        isTrue,
      );
    });

    test('all done counts as complete', () {
      expect(
        LedgerLogic.isDayComplete(
          doneByCommitment: const [true, true, true],
          isPaused: false,
        ),
        isTrue,
      );
    });

    test('any miss means incomplete', () {
      expect(
        LedgerLogic.isDayComplete(
          doneByCommitment: const [true, false],
          isPaused: false,
        ),
        isFalse,
      );
    });

    test('empty commitment list is incomplete', () {
      expect(
        LedgerLogic.isDayComplete(doneByCommitment: const [], isPaused: false),
        isFalse,
      );
    });
  });
}
