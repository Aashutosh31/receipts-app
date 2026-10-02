import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/squads/domain/squad_models.dart';

void main() {
  group('invite codes', () {
    test('accepts 6 uppercase alphanumerics', () {
      expect(isValidInviteCode('ABC123'), isTrue);
      expect(isValidInviteCode('ABCDEF'), isTrue);
      expect(isValidInviteCode('123456'), isTrue);
    });

    test('rejects wrong shapes', () {
      expect(isValidInviteCode(''), isFalse);
      expect(isValidInviteCode('ABC12'), isFalse);
      expect(isValidInviteCode('ABC1234'), isFalse);
      expect(isValidInviteCode('ABC-12'), isFalse);
      expect(isValidInviteCode('ABC 12'), isFalse);
    });

    test('normalizes user input', () {
      expect(normalizeInviteCode('  abc123  '), 'ABC123');
      expect(isValidInviteCode('abc123'), isTrue);
    });
  });

  group('SquadFeedRow.fromMap', () {
    test('parses full rows', () {
      final SquadFeedRow row = SquadFeedRow.fromMap(<String, dynamic>{
        'member_user_id': 'u1',
        'display_name': 'Asha',
        'day_number': 12,
        'today_status': 'kept',
        'current_streak': 5,
        'missed_count': 2,
      });
      expect(row.memberUserId, 'u1');
      expect(row.hasContract, isTrue);
      expect(row.todayStatus, 'kept');
    });

    test('contract-less members parse with nulls', () {
      final SquadFeedRow row = SquadFeedRow.fromMap(<String, dynamic>{
        'member_user_id': 'u2',
        'display_name': 'Squadmate',
        'day_number': null,
        'today_status': null,
        'current_streak': null,
        'missed_count': null,
      });
      expect(row.hasContract, isFalse);
      expect(row.todayStatus, isNull);
    });
  });

  test('exactly one preset nudge message exists', () {
    expect(nudgePresetMessage.isNotEmpty, isTrue);
  });
}
