// Part A tests: outbox queue, rejection honesty, cache round-trip, and
// user isolation. Drift runs in-memory (NativeDatabase.memory) so no device
// or Supabase is involved.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:receipts/features/contract/data/contract_repository.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';
import 'package:receipts/features/ledger/data/ledger_repository.dart';
import 'package:receipts/features/ledger/domain/ledger_models.dart';
import 'package:receipts/features/offline/data/local_cache.dart';
import 'package:receipts/features/offline/data/local_database.dart';
import 'package:receipts/features/offline/data/sync_repository.dart';

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

Commitment _commitment() {
  return Commitment(
    id: 'c1',
    contractId: 'contract-1',
    userId: 'user-1',
    title: 'Run 20 minutes',
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

LedgerEntry _entry(DateTime day) {
  return LedgerEntry(
    day: day,
    commitmentId: 'c1',
    commitmentTitle: 'Run 20 minutes',
    status: 'done',
    done: true,
    isPaused: false,
  );
}

class FakeLedger implements LedgerRepository {
  int submitCalls = 0;
  Future<void> Function()? onSubmit;

  @override
  Future<List<LedgerEntry>> fetchLedger(String contractId) async =>
      <LedgerEntry>[_entry(DateTime.utc(2026, 10, 5))];

  @override
  Future<StreakInfo> fetchStreak(String contractId) async => StreakInfo(
    currentStreak: 4,
    recoveriesUsed: 0,
    mode: 'hard',
    today: DateTime.utc(2026, 10, 5),
  );

  @override
  Future<void> submitCheckIn({
    required String commitmentId,
    required DateTime day,
  }) async {
    submitCalls += 1;
    final Future<void> Function()? hook = onSubmit;
    if (hook != null) {
      await hook();
    }
  }
}

class FakeContracts implements ContractRepository {
  @override
  Future<List<Contract>> fetchContracts() async => <Contract>[_contract()];

  @override
  Future<Contract?> fetchActiveContract() async => _contract();

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async =>
      <Commitment>[_commitment()];

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

Future<LocalCache> _memoryCache() async {
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return LocalCache(db);
}

void main() {
  group('outbox queue', () {
    test('enqueue lists a pending row', () async {
      final LocalCache cache = await _memoryCache();
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run 20 minutes',
        day: DateTime.utc(2026, 10, 5),
      );
      final List<OutboxCheckin> rows = await cache.pendingOutbox('user-1');
      expect(rows, hasLength(1));
      expect(rows.first.status, 'pending');
      expect(rows.first.day, '2026-10-05');
    });

    test('successful sync sends and deletes the row', () async {
      final LocalCache cache = await _memoryCache();
      final FakeLedger ledger = FakeLedger();
      final SupabaseSyncRepository sync = SupabaseSyncRepository(
        cache: cache,
        ledger: ledger,
        contracts: FakeContracts(),
      );
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run 20 minutes',
        day: DateTime.utc(2026, 10, 5),
      );
      final SyncReport report = await sync.syncNow(userId: 'user-1');
      expect(report.sent, 1);
      expect(report.failed, 0);
      expect(await cache.pendingOutbox('user-1'), isEmpty);
      expect(ledger.submitCalls, 1);
    });

    test('grace-window rejection is kept verbatim, never dropped', () async {
      const String serverMessage =
          'check_in day 2026-10-01 is not today (2026-10-05); '
          'backfill is forbidden';
      final LocalCache cache = await _memoryCache();
      final FakeLedger ledger = FakeLedger();
      ledger.onSubmit = () async {
        throw const LedgerFailure(serverMessage);
      };
      final SupabaseSyncRepository sync = SupabaseSyncRepository(
        cache: cache,
        ledger: ledger,
        contracts: FakeContracts(),
      );
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run 20 minutes',
        day: DateTime.utc(2026, 10, 1),
      );
      final SyncReport first = await sync.syncNow(userId: 'user-1');
      expect(first.sent, 0);
      expect(first.failed, 1);
      expect(first.failedMessages, <String>[serverMessage]);

      final List<OutboxCheckin> rows = await cache.pendingOutbox('user-1');
      expect(rows, hasLength(1));
      expect(rows.first.status, 'failed');
      expect(rows.first.errorMessage, serverMessage);

      // A second sync does not resubmit the failed row (no churn), and the
      // row is still there for the user to dismiss.
      final SyncReport second = await sync.syncNow(userId: 'user-1');
      expect(ledger.submitCalls, 1);
      expect(second.failed, 1);
      expect(await cache.pendingOutbox('user-1'), hasLength(1));

      await sync.dismissFailed(rows.first.localId);
      expect(await cache.pendingOutbox('user-1'), isEmpty);
    });

    test('duplicate rejection counts as sent', () async {
      final LocalCache cache = await _memoryCache();
      final FakeLedger ledger = FakeLedger();
      ledger.onSubmit = () async {
        throw const LedgerFailure(
          'duplicate key value violates unique constraint '
          '"check_ins_commitment_id_day_key" (23505)',
        );
      };
      final SupabaseSyncRepository sync = SupabaseSyncRepository(
        cache: cache,
        ledger: ledger,
        contracts: FakeContracts(),
      );
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run 20 minutes',
        day: DateTime.utc(2026, 10, 5),
      );
      final SyncReport report = await sync.syncNow(userId: 'user-1');
      expect(report.sent, 1);
      expect(report.failed, 0);
      expect(await cache.pendingOutbox('user-1'), isEmpty);
    });

    test('signed-out sync is a no-op', () async {
      final LocalCache cache = await _memoryCache();
      final SupabaseSyncRepository sync = SupabaseSyncRepository(
        cache: cache,
        ledger: FakeLedger(),
        contracts: FakeContracts(),
      );
      final SyncReport report = await sync.syncNow(userId: null);
      expect(report.sent, 0);
      expect(report.cacheRefreshed, isFalse);
    });
  });

  group('cache snapshot', () {
    test('write then read round-trips contract data', () async {
      final LocalCache cache = await _memoryCache();
      await cache.writeSnapshot(
        userId: 'user-1',
        contract: _contract(),
        commitments: <Commitment>[_commitment()],
        ledger: <LedgerEntry>[_entry(DateTime.utc(2026, 10, 5))],
        streak: StreakInfo(
          currentStreak: 4,
          recoveriesUsed: 0,
          mode: 'hard',
          today: DateTime.utc(2026, 10, 5),
        ),
      );
      final Contract? contract = await cache.readContract('user-1');
      expect(contract?.id, 'contract-1');
      final List<Commitment> commitments = await cache.readCommitments(
        'user-1',
        'contract-1',
      );
      expect(commitments.map((Commitment c) => c.title), ['Run 20 minutes']);
      final List<LedgerEntry> ledger = await cache.readLedger(
        'user-1',
        'contract-1',
      );
      expect(ledger, hasLength(1));
      expect(ledger.first.done, isTrue);
      final CachedStreak? streak = await cache.readStreak(
        'user-1',
        'contract-1',
      );
      expect(streak?.currentStreak, 4);
    });

    test('rows are invisible to other users', () async {
      final LocalCache cache = await _memoryCache();
      await cache.writeSnapshot(
        userId: 'user-1',
        contract: _contract(),
        commitments: <Commitment>[_commitment()],
        ledger: <LedgerEntry>[_entry(DateTime.utc(2026, 10, 5))],
        streak: StreakInfo(
          currentStreak: 4,
          recoveriesUsed: 0,
          mode: 'hard',
          today: DateTime.utc(2026, 10, 5),
        ),
      );
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run 20 minutes',
        day: DateTime.utc(2026, 10, 5),
      );
      expect(await cache.readContract('user-2'), isNull);
      expect(await cache.readLedger('user-2', 'contract-1'), isEmpty);
      expect(await cache.pendingOutbox('user-2'), isEmpty);
    });
  });

  group('isOnlineResult', () {
    test('wifi/mobile/ethernet are online', () {
      expect(isOnlineResult(const [ConnectivityResult.wifi]), isTrue);
      expect(isOnlineResult(const [ConnectivityResult.mobile]), isTrue);
      expect(isOnlineResult(const [ConnectivityResult.ethernet]), isTrue);
    });

    test('none, bluetooth-only, or empty are offline', () {
      expect(isOnlineResult(const [ConnectivityResult.none]), isFalse);
      expect(isOnlineResult(const [ConnectivityResult.bluetooth]), isFalse);
      expect(isOnlineResult(const []), isFalse);
    });
  });
}
