import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/reminders/domain/message_engine.dart';

ReminderContext _ctx({
  ReminderKind kind = ReminderKind.upcoming,
  int misses = 0,
  ReminderTone tone = ReminderTone.blunt,
  bool paused = false,
  String? excuse,
  int? done,
  int? total,
}) {
  return ReminderContext(
    kind: kind,
    title: 'Run 20 minutes',
    targetTime: '05:30',
    nowTime: '06:40',
    streak: 12,
    dayNumber: 23,
    lastExcuse: excuse,
    doneCount: done,
    totalCount: total,
    consecutiveMisses: misses,
    toneCap: tone,
    isPaused: paused,
  );
}

final RegExp _banned = RegExp(
  r'\b(weight|fat|thin|skinny|diet|calori|body|appearance|ugly|stupid|idiot|loser|pathetic|worthless|shame|disgusting)\b',
  caseSensitive: false,
);

void main() {
  group('tierFor', () {
    test('no misses is calm', () {
      expect(tierFor(_ctx()), ReminderTier.calm);
    });

    test('one miss is firm, two or more is blunt', () {
      expect(tierFor(_ctx(misses: 1)), ReminderTier.firm);
      expect(tierFor(_ctx(misses: 2)), ReminderTier.blunt);
      expect(tierFor(_ctx(misses: 5)), ReminderTier.blunt);
    });

    test('tone setting caps escalation', () {
      expect(
        tierFor(_ctx(misses: 5, tone: ReminderTone.calm)),
        ReminderTier.calm,
      );
      expect(
        tierFor(_ctx(misses: 5, tone: ReminderTone.firm)),
        ReminderTier.firm,
      );
      expect(
        tierFor(_ctx(misses: 0, tone: ReminderTone.calm)),
        ReminderTier.calm,
      );
    });

    test('pause always softens to calm', () {
      expect(tierFor(_ctx(misses: 5, paused: true)), ReminderTier.calm);
    });
  });

  group('pickMessage', () {
    test('fills every placeholder with real data', () {
      // Upcoming templates all carry title + target; last-call templates
      // carry day + counters. Sample both.
      for (int salt = 0; salt < 40; salt++) {
        final ReminderMessage upcoming = pickMessage(
          _ctx(kind: ReminderKind.upcoming),
          salt: 'up-$salt',
        );
        expect(upcoming.body.contains('{'), isFalse);
        expect(upcoming.body, contains('Run 20 minutes'));
        expect(upcoming.body, contains('05:30'));

        final ReminderMessage lastCall = pickMessage(
          _ctx(kind: ReminderKind.lastCall, done: 2, total: 3),
          salt: 'lc-$salt',
        );
        expect(lastCall.body.contains('{'), isFalse);
        expect(lastCall.title, contains('23'));
        expect(RegExp(r'2\s*(of|/)\s*3').hasMatch(lastCall.body), isTrue);
      }
    });

    test('follow-up uses the now-versus-target confrontation', () {
      bool seen = false;
      for (int salt = 0; salt < 40; salt++) {
        final ReminderMessage message = pickMessage(
          _ctx(kind: ReminderKind.followUp),
          salt: 'salt-$salt',
        );
        if (message.body.contains('You said')) {
          seen = true;
        }
      }
      expect(seen, isTrue);
    });

    test('paused copy never mentions misses', () {
      for (int salt = 0; salt < 60; salt++) {
        final ReminderMessage message = pickMessage(
          _ctx(misses: 4, paused: true),
          salt: 'salt-$salt',
        );
        expect(message.body.toLowerCase(), isNot(contains('miss')));
      }
    });

    test('same salt renders the same text', () {
      final ReminderMessage a = pickMessage(_ctx(), salt: 'same-day');
      final ReminderMessage b = pickMessage(_ctx(), salt: 'same-day');
      expect(a.body, b.body);
      expect(a.title, b.title);
    });

    test('at least 60 distinct templates exist', () {
      final Set<String> bodies = <String>{};
      for (final ReminderTier tier in ReminderTier.values) {
        for (final ReminderKind kind in ReminderKind.values) {
          for (int salt = 0; salt < 120; salt++) {
            bodies.add(
              pickMessage(
                _ctx(
                  kind: kind,
                  misses: tier == ReminderTier.calm
                      ? 0
                      : tier == ReminderTier.firm
                      ? 1
                      : 3,
                ),
                salt: 'salt-$salt',
              ).body,
            );
          }
        }
      }
      expect(bodies.length, greaterThanOrEqualTo(60));
    });

    test('no template insults or references body/weight', () {
      for (final ReminderTier tier in ReminderTier.values) {
        for (final ReminderKind kind in ReminderKind.values) {
          for (int salt = 0; salt < 60; salt++) {
            final ReminderMessage message = pickMessage(
              _ctx(
                kind: kind,
                misses: tier == ReminderTier.calm
                    ? 0
                    : tier == ReminderTier.firm
                    ? 1
                    : 3,
                excuse: 'tired',
                done: 1,
                total: 3,
              ),
              salt: 'salt-$salt',
            );
            expect(
              _banned.hasMatch(message.body),
              isFalse,
              reason: 'banned word in: ${message.body}',
            );
            expect(_banned.hasMatch(message.title), isFalse);
          }
        }
      }
    });
  });
}
