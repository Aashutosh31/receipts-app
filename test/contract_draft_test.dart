import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';

ContractDraft _validDraft() {
  final ContractDraft draft = ContractDraft();
  draft.commitments[0].title = 'Run 20 minutes';
  draft.commitments[0].targetTime = '06:30';
  draft.commitments[1].title = 'Read 10 pages';
  draft.commitments[2].title = 'No sugar';
  draft.mode = ContractModeDto.hard;
  draft.signature = 'Tester';
  return draft;
}

void main() {
  group('ContractDraft.validate', () {
    test('valid draft passes', () {
      expect(_validDraft().validate(), isNull);
    });

    test('empty title fails', () {
      final ContractDraft draft = _validDraft();
      draft.commitments[1].title = '   ';
      expect(draft.validate(), contains('Commitment 2'));
    });

    test('overlong title fails', () {
      final ContractDraft draft = _validDraft();
      draft.commitments[0].title = 'x' * 121;
      expect(draft.validate(), contains('too long'));
    });

    test('bad time fails, empty time passes', () {
      final ContractDraft draft = _validDraft();
      draft.commitments[0].targetTime = '25:00';
      expect(draft.validate(), contains('06:30'));
      draft.commitments[0].targetTime = '';
      expect(draft.validate(), isNull);
    });

    test('missing mode fails', () {
      final ContractDraft draft = _validDraft();
      draft.mode = null;
      expect(draft.validate(), contains('Mode'));
    });

    test('missing signature fails', () {
      final ContractDraft draft = _validDraft();
      draft.signature = '  ';
      expect(draft.validate(), contains('sign'));
    });
  });

  group('ContractDraft.endDate', () {
    test('ends 90 days after start', () {
      final ContractDraft draft = ContractDraft();
      expect(
        draft.endDate(DateTime.utc(2026, 10, 1)),
        DateTime.utc(2026, 12, 30),
      );
    });
  });
}
