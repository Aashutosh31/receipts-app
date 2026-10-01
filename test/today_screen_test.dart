// Today screen widget test with mocked repositories (fakes implement the
// repository interfaces; no Supabase involved).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/contract/data/contract_repository.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';
import 'package:receipts/features/contract/presentation/contract_providers.dart';
import 'package:receipts/features/excuse/data/excuse_repository.dart';
import 'package:receipts/features/excuse/domain/excuse_models.dart';
import 'package:receipts/features/ledger/data/ledger_repository.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';
import 'package:receipts/features/ledger/presentation/ledger_providers.dart';
import 'package:receipts/features/ledger/presentation/today_screen.dart';

final DateTime _today = DateTime.utc(2026, 10, 5);

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

Commitment _commitment(String id, String title) {
  return Commitment(
    id: id,
    contractId: 'contract-1',
    userId: 'user-1',
    title: title,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

class FakeContractRepository implements ContractRepository {
  @override
  Future<List<Contract>> fetchContracts() async => <Contract>[_contract()];

  @override
  Future<Contract?> fetchActiveContract() async => _contract();

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async =>
      <Commitment>[
        _commitment('c1', 'Run 20 minutes'),
        _commitment('c2', 'Read 10 pages'),
      ];

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
}

class FakeLedgerRepository implements LedgerRepository {
  final Set<String> doneIds = <String>{};

  List<LedgerEntry> _rows() {
    return <LedgerEntry>[
      for (final (String id, String title) in <(String, String)>[
        ('c1', 'Run 20 minutes'),
        ('c2', 'Read 10 pages'),
      ])
        LedgerEntry(
          day: _today,
          commitmentId: id,
          commitmentTitle: title,
          status: doneIds.contains(id) ? 'done' : 'missed',
          done: doneIds.contains(id),
          isPaused: false,
        ),
    ];
  }

  @override
  Future<List<LedgerEntry>> fetchLedger(String contractId) async => _rows();

  @override
  Future<StreakInfo> fetchStreak(String contractId) async => StreakInfo(
    currentStreak: 4,
    recoveriesUsed: 0,
    mode: 'hard',
    today: _today,
  );

  @override
  Future<void> submitCheckIn({
    required String commitmentId,
    required DateTime day,
  }) async {
    doneIds.add(commitmentId);
  }
}

class FakeExcuseRepository implements ExcuseRepository {
  @override
  Future<List<Excuse>> fetchExcuses() async => <Excuse>[];

  @override
  Future<void> fileExcuse({
    required String commitmentId,
    required DateTime day,
    required ExcuseReason reason,
    String? freeText,
  }) async {}
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      contractRepositoryProvider.overrideWithValue(FakeContractRepository()),
      ledgerRepositoryProvider.overrideWithValue(FakeLedgerRepository()),
      excuseRepositoryProvider.overrideWithValue(FakeExcuseRepository()),
    ],
    child: const MaterialApp(home: TodayScreen()),
  );
}

void main() {
  testWidgets('shows streak, commitments, and honest status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Run 20 minutes'), findsOneWidget);
    expect(find.text('Read 10 pages'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.textContaining('Nothing logged yet'), findsOneWidget);
  });

  testWidgets('Done asks for final confirm, then logs it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Done').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot be edited'), findsOneWidget);

    await tester.tap(find.text('Log done'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 of 2 done'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
