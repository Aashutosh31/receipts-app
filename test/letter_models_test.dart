import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/letters/domain/letter_models.dart';

void main() {
  group('countdownDays', () {
    test('future unlock counts whole days', () {
      expect(
        countdownDays(DateTime.utc(2026, 10, 31), DateTime.utc(2026, 10, 1)),
        30,
      );
    });

    test('arrival day and past are zero or negative', () {
      expect(
        countdownDays(DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 1)),
        0,
      );
      expect(
        countdownDays(DateTime.utc(2026, 9, 30), DateTime.utc(2026, 10, 1)),
        -1,
      );
    });

    test('compares calendar days, not instants', () {
      expect(
        countdownDays(
          DateTime.utc(2026, 10, 2, 23, 59),
          DateTime.utc(2026, 10, 1, 0, 1),
        ),
        1,
      );
    });
  });

  group('milestoneLabel', () {
    test('day 1 and numbered milestones', () {
      expect(milestoneLabel(0), 'Day 1 letter');
      expect(milestoneLabel(30), 'Day 30 letter');
      expect(milestoneLabel(90), 'Day 90 letter');
    });

    test('all supported milestones exist', () {
      expect(letterMilestones, <int>[0, 30, 60, 90]);
    });
  });

  group('validateLetterBody', () {
    test('empty fails, normal passes, overlong fails', () {
      expect(validateLetterBody('   '), isNotNull);
      expect(validateLetterBody('Dear me.'), isNull);
      expect(validateLetterBody('x' * 5001), isNotNull);
      expect(validateLetterBody('x' * 5000), isNull);
    });
  });

  group('LetterEntry.fromMap', () {
    test('locked rows carry null body', () {
      final LetterEntry locked = LetterEntry.fromMap(<String, dynamic>{
        'id': 'l1',
        'unlock_day_number': 30,
        'unlock_date': '2026-10-31',
        'is_unlocked': false,
        'body': null,
      });
      expect(locked.isUnlocked, isFalse);
      expect(locked.body, isNull);
      expect(locked.unlockDayNumber, 30);
    });

    test('unlocked rows carry the body', () {
      final LetterEntry open = LetterEntry.fromMap(<String, dynamic>{
        'id': 'l0',
        'unlock_day_number': 0,
        'unlock_date': '2026-10-01',
        'is_unlocked': true,
        'body': 'Dear me.',
      });
      expect(open.isUnlocked, isTrue);
      expect(open.body, 'Dear me.');
    });
  });
}
