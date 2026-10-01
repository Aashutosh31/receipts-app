import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/utils/streak_logic.dart';

void main() {
  group('StreakLogic hard mode', () {
    test('counts consecutive done days', () {
      final result = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: const [
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: true),
        ],
        mode: ContractMode.hard,
      );
      expect(result.currentStreak, 3);
      expect(result.recoveriesUsed, 0);
    });

    test('any miss resets the streak', () {
      final result = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: const [
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: true),
        ],
        mode: ContractMode.hard,
      );
      expect(result.currentStreak, 1);
    });

    test('paused days are skipped, never break', () {
      final result = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: const [
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: false, isPaused: true),
          DailyStreakInput(allDone: true),
        ],
        mode: ContractMode.hard,
      );
      expect(result.currentStreak, 2);
    });
  });

  group('StreakLogic kind mode', () {
    test('tolerates up to 2 missed days', () {
      final result = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: const [
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: true),
        ],
        mode: ContractMode.kind,
      );
      expect(result.currentStreak, 4);
      expect(result.recoveriesUsed, 2);
    });

    test('third miss resets the streak', () {
      final result = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: const [
          DailyStreakInput(allDone: true),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: false),
          DailyStreakInput(allDone: true),
        ],
        mode: ContractMode.kind,
      );
      expect(result.currentStreak, 1);
      expect(result.recoveriesUsed, 2);
    });
  });
}
