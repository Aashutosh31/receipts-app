// Letters unlock-state tests: locked cards show countdowns without bodies,
// unlocked cards reveal. Fakes stand in for repositories (incl. the RPC).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/presentation/auth_providers.dart';
import 'package:receipts/features/contract/data/contract_repository.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';
import 'package:receipts/features/contract/presentation/contract_providers.dart';
import 'package:receipts/features/ledger/data/ledger_repository.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';
import 'package:receipts/features/ledger/presentation/ledger_providers.dart';
import 'package:receipts/features/letters/data/letter_repository.dart';
import 'package:receipts/features/letters/domain/letter_models.dart';
import 'package:receipts/features/letters/presentation/letter_providers.dart';
import 'package:receipts/features/letters/presentation/letters_screen.dart';

import 'test_fakes.dart';

Contract _contract() {
  return Contract(
    id: 'contract-1',
    userId: 'user-1',
    startDate: DateTime.utc(2026, 10, 1),
    endDate: DateTime.utc(2026, 12, 30),
    mode: ContractModeDto.hard,
    status: ContractStatus.active,
    kindRecoveriesUsed: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

class _FakeContracts implements ContractRepository {
  @override
  Future<List<Contract>> fetchContracts() async => <Contract>[_contract()];

  @override
  Future<Contract?> fetchActiveContract() async => _contract();

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async =>
      <Commitment>[];

  @override
  Future<String> createContract({
    required DateTime startDate,
    required ContractModeDto mode,
    required List<CommitmentDraft> commitments,
    String reason = 'initial contract lock',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Pause>> fetchPauses(String contractId) async => <Pause>[];

  @override
  Future<void> declarePause({
    required String contractId,
    required String type,
    required DateTime startDay,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> endPause({
    required String pauseId,
    required DateTime endDay,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> retireCommitment({
    required String commitmentId,
    required String contractId,
    required String reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ContractChange>> fetchContractChanges(String contractId) async {
    return <ContractChange>[];
  }
}

class _FakeLedger implements LedgerRepository {
  @override
  Future<List<LedgerEntry>> fetchLedger(String contractId) async =>
      <LedgerEntry>[];

  @override
  Future<StreakInfo> fetchStreak(String contractId) async => StreakInfo(
    currentStreak: 5,
    recoveriesUsed: 0,
    mode: 'hard',
    today: DateTime.utc(2026, 10, 5),
  );

  @override
  Future<void> submitCheckIn({
    required String commitmentId,
    required DateTime day,
  }) async {}
}

class _FakeLetters implements LetterRepository {
  @override
  Future<List<LetterEntry>> fetchLetters(String contractId) async =>
      <LetterEntry>[
        LetterEntry(
          id: 'l0',
          unlockDayNumber: 0,
          unlockDate: DateTime.utc(2026, 10, 1),
          isUnlocked: true,
          body: 'Dear me, keep going.',
        ),
        LetterEntry(
          id: 'l30',
          unlockDayNumber: 30,
          unlockDate: DateTime.utc(2026, 10, 31),
          isUnlocked: false,
        ),
      ];

  @override
  Future<void> writeLetter({
    required String contractId,
    required int unlockDayNumber,
    required String body,
  }) async {}
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(initialUserId: 'user-1'),
      ),
      contractRepositoryProvider.overrideWithValue(_FakeContracts()),
      ledgerRepositoryProvider.overrideWithValue(_FakeLedger()),
      letterRepositoryProvider.overrideWithValue(_FakeLetters()),
    ],
    child: const MaterialApp(home: LettersScreen()),
  );
}

void main() {
  testWidgets('locked cards countdown, unlocked cards open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Day-1 letter is unlocked: body stays hidden until reveal, Read offered.
    expect(find.text('Day 1 letter'), findsOneWidget);
    expect(find.text('Read it'), findsOneWidget);
    expect(find.textContaining('Dear me, keep going.'), findsNothing);

    // Day-30 letter is locked: countdown shown, no body, no Read action.
    expect(find.text('Day 30 letter'), findsOneWidget);
    expect(find.textContaining('Unlocks in 26 days'), findsOneWidget);
    expect(find.text('Read it'), findsOneWidget);
  });

  test('letters provider surfaces RPC lock states', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUserId: 'user-1'),
        ),
        letterRepositoryProvider.overrideWithValue(_FakeLetters()),
      ],
    );
    addTearDown(container.dispose);
    // Hold a listener: autoDispose providers need one to stay alive while
    // the auth stream settles (same pattern as auth_scope_test.dart).
    final ProviderSubscription<AsyncValue<List<LetterEntry>>> sub = container
        .listen(lettersProvider('contract-1'), (prev, next) {});
    addTearDown(sub.close);

    final List<LetterEntry> letters = await container.read(
      lettersProvider('contract-1').future,
    );
    final LetterEntry locked = letters.firstWhere(
      (LetterEntry l) => l.unlockDayNumber == 30,
    );
    expect(locked.isUnlocked, isFalse);
    expect(locked.body, isNull);
    final LetterEntry open = letters.firstWhere(
      (LetterEntry l) => l.unlockDayNumber == 0,
    );
    expect(open.isUnlocked, isTrue);
    expect(open.body, isNotNull);
  });
}
