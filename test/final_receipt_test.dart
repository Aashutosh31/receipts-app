import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/utils/streak_logic.dart';
import 'package:receipts/features/excuse/domain/excuse_models.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';
import 'package:receipts/features/letters/domain/final_receipt.dart';
import 'package:receipts/features/letters/domain/letter_models.dart';

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

LetterEntry _letter(int milestone, {String? body, bool unlocked = true}) {
  return LetterEntry(
    id: 'l$milestone',
    unlockDayNumber: milestone,
    unlockDate: DateTime.utc(2026, 10, 1).add(Duration(days: milestone)),
    isUnlocked: unlocked,
    body: body,
  );
}

void main() {
  final DateTime today = DateTime.utc(2026, 10, 10);

  FinalReceiptStats build({
    required List<LedgerEntry> ledger,
    List<Excuse> excuses = const <Excuse>[],
  }) {
    return computeFinalReceipt(
      ledger: ledger,
      excuses: excuses,
      letters: <LetterEntry>[_letter(0, body: 'Dear me.')],
      serverToday: today,
      mode: ContractMode.hard,
    );
  }

  group('computeFinalReceipt', () {
    test('promised vs kept with rate', () {
      final FinalReceiptStats stats = build(
        ledger: <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 8), status: 'done', done: true),
          _row(day: DateTime.utc(2026, 10, 9), status: 'missed', done: false),
          _row(day: DateTime.utc(2026, 10, 10), status: 'done', done: true),
        ],
      );
      expect(stats.promised, 3);
      expect(stats.kept, 2);
      expect(stats.keptRate, closeTo(2 / 3, 0.001));
      expect(stats.longestStreak, 1);
    });

    test('paused days are skipped, future days excluded', () {
      final FinalReceiptStats stats = build(
        ledger: <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 8), status: 'done', done: true),
          _row(day: DateTime.utc(2026, 10, 9), status: 'paused', paused: true),
          _row(day: DateTime.utc(2026, 10, 12), status: 'promised'),
        ],
      );
      expect(stats.promised, 1);
      expect(stats.kept, 1);
      expect(stats.longestStreak, 1);
    });

    test('longest streak spans misses', () {
      final FinalReceiptStats stats = build(
        ledger: <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 6), status: 'done', done: true),
          _row(day: DateTime.utc(2026, 10, 7), status: 'done', done: true),
          _row(day: DateTime.utc(2026, 10, 8), status: 'done', done: true),
          _row(day: DateTime.utc(2026, 10, 9), status: 'missed', done: false),
          _row(day: DateTime.utc(2026, 10, 10), status: 'done', done: true),
        ],
      );
      expect(stats.longestStreak, 3);
    });

    test('top excuse and day-one letter surface', () {
      Excuse excuse(String id, DateTime day, ExcuseReason reason) {
        return Excuse(id: id, commitmentId: 'c1', day: day, reason: reason);
      }

      final FinalReceiptStats stats = build(
        ledger: <LedgerEntry>[
          _row(day: DateTime.utc(2026, 10, 10), status: 'done', done: true),
        ],
        excuses: <Excuse>[
          excuse('e1', DateTime.utc(2026, 10, 8), ExcuseReason.tired),
          excuse('e2', DateTime.utc(2026, 10, 9), ExcuseReason.tired),
          excuse('e3', DateTime.utc(2026, 10, 9), ExcuseReason.busy),
        ],
      );
      expect(stats.topExcuse, 'tired');
      expect(stats.topExcuseCount, 2);
      expect(stats.dayOneLetter?.body, 'Dear me.');
    });

    test('empty ledger is a zeroed receipt', () {
      final FinalReceiptStats stats = build(ledger: const <LedgerEntry>[]);
      expect(stats.promised, 0);
      expect(stats.kept, 0);
      expect(stats.keptRate, 0);
      expect(stats.longestStreak, 0);
      expect(stats.topExcuse, isNull);
    });
  });

  group('receiptShareText', () {
    test('shares aggregates only, never letter text', () {
      const String secret = 'my deepest secret here';
      final String text = receiptShareText(
        promised: 90,
        kept: 72,
        longestStreak: 14,
      );
      expect(text, contains('72 of 90 kept (80%)'));
      expect(text, contains('14'));
      expect(text.contains(secret), isFalse);
    });
  });
}
