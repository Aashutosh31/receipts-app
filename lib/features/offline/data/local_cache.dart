// LocalCache: typed read/write access to the drift offline store.
// All reads/writes are scoped by (userId, contractId): device-sharing users
// can never see each other's cached rows.

import 'package:drift/drift.dart';

import '../../contract/domain/contract_models.dart';
import '../../ledger/domain/ledger_models.dart';
import 'local_database.dart';

String _isoDay(DateTime day) =>
    formatServerDay(DateTime(day.year, day.month, day.day));

class LocalCache {
  LocalCache(this._db);

  final AppDatabase _db;

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  /// Replaces the whole server snapshot for one contract in a transaction.
  Future<void> writeSnapshot({
    required String userId,
    required Contract contract,
    required List<Commitment> commitments,
    required List<LedgerEntry> ledger,
    required StreakInfo streak,
  }) async {
    final String now = _nowIso();
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedContracts,
      )..where((t) => t.userId.equals(userId))).go();
      await (_db.delete(
        _db.cachedCommitments,
      )..where((t) => t.userId.equals(userId))).go();
      await (_db.delete(
        _db.cachedLedgerEntries,
      )..where((t) => t.userId.equals(userId))).go();
      await (_db.delete(
        _db.cachedStreaks,
      )..where((t) => t.userId.equals(userId))).go();

      await _db
          .into(_db.cachedContracts)
          .insert(
            CachedContractsCompanion.insert(
              id: contract.id,
              userId: userId,
              startDate: formatServerDay(contract.startDate),
              endDate: formatServerDay(contract.endDate),
              mode: contract.mode.name,
              status: contract.status.name,
              kindRecoveriesUsed: contract.kindRecoveriesUsed,
              updatedAt: now,
            ),
          );
      for (final Commitment c in commitments) {
        await _db
            .into(_db.cachedCommitments)
            .insert(
              CachedCommitmentsCompanion.insert(
                id: c.id,
                contractId: c.contractId,
                userId: userId,
                title: c.title,
                targetTime: Value(c.targetTime),
                sortOrder: c.sortOrder,
                retiredAt: Value(
                  c.retiredAt == null ? null : _isoDay(c.retiredAt!),
                ),
                updatedAt: now,
              ),
            );
      }
      for (final LedgerEntry e in ledger) {
        await _db
            .into(_db.cachedLedgerEntries)
            .insert(
              CachedLedgerEntriesCompanion.insert(
                key: '${e.commitmentId}|${formatServerDay(e.day)}',
                userId: userId,
                contractId: contract.id,
                commitmentId: e.commitmentId,
                title: e.commitmentTitle,
                day: formatServerDay(e.day),
                status: e.status,
                done: Value(e.done),
                isPaused: Value(e.isPaused),
              ),
            );
      }
      await _db
          .into(_db.cachedStreaks)
          .insert(
            CachedStreaksCompanion.insert(
              contractId: contract.id,
              userId: userId,
              currentStreak: streak.currentStreak,
              recoveriesUsed: streak.recoveriesUsed,
              mode: streak.mode,
              today: formatServerDay(streak.today),
              asOf: now,
            ),
          );
    });
  }

  Future<Contract?> readContract(String userId) async {
    final List<CachedContract> rows = await (_db.select(
      _db.cachedContracts,
    )..where((t) => t.userId.equals(userId))).get();
    if (rows.isEmpty) {
      return null;
    }
    final CachedContract row = rows.first;
    return Contract(
      id: row.id,
      userId: row.userId,
      startDate: parseServerDay(row.startDate),
      endDate: parseServerDay(row.endDate),
      mode: row.mode == 'hard' ? ContractModeDto.hard : ContractModeDto.kind,
      status: ContractStatus.values.firstWhere(
        (ContractStatus s) => s.name == row.status,
        orElse: () => ContractStatus.active,
      ),
      kindRecoveriesUsed: row.kindRecoveriesUsed,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<List<Commitment>> readCommitments(
    String userId,
    String contractId,
  ) async {
    final List<CachedCommitment> rows =
        await (_db.select(_db.cachedCommitments)
              ..where(
                (t) =>
                    t.userId.equals(userId) & t.contractId.equals(contractId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows
        .map(
          (CachedCommitment row) => Commitment(
            id: row.id,
            contractId: row.contractId,
            userId: row.userId,
            title: row.title,
            targetTime: row.targetTime,
            sortOrder: row.sortOrder,
            createdAt: DateTime.now().toUtc(),
            retiredAt: row.retiredAt == null
                ? null
                : parseServerDay(row.retiredAt!),
          ),
        )
        .toList();
  }

  Future<List<LedgerEntry>> readLedger(String userId, String contractId) async {
    final List<CachedLedgerEntry> rows =
        await (_db.select(_db.cachedLedgerEntries)..where(
              (t) => t.userId.equals(userId) & t.contractId.equals(contractId),
            ))
            .get();
    final List<LedgerEntry> entries =
        rows
            .map(
              (CachedLedgerEntry row) => LedgerEntry(
                day: parseServerDay(row.day),
                commitmentId: row.commitmentId,
                commitmentTitle: row.title,
                status: row.status,
                done: row.done,
                isPaused: row.isPaused,
              ),
            )
            .toList()
          ..sort((LedgerEntry a, LedgerEntry b) {
            final int byDay = a.day.compareTo(b.day);
            return byDay != 0
                ? byDay
                : a.commitmentTitle.compareTo(b.commitmentTitle);
          });
    return entries;
  }

  Future<CachedStreak?> readStreak(String userId, String contractId) async {
    final List<CachedStreak> rows =
        await (_db.select(_db.cachedStreaks)..where(
              (t) => t.userId.equals(userId) & t.contractId.equals(contractId),
            ))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Optimistic local done row so offline check-ins show immediately.
  /// The server remains the judge at sync time.
  Future<void> writeLocalDone({
    required String userId,
    required String contractId,
    required String commitmentId,
    required String title,
    required DateTime day,
  }) async {
    await _db
        .into(_db.cachedLedgerEntries)
        .insertOnConflictUpdate(
          CachedLedgerEntriesCompanion.insert(
            key: '$commitmentId|${formatServerDay(day)}',
            userId: userId,
            contractId: contractId,
            commitmentId: commitmentId,
            title: title,
            day: formatServerDay(day),
            status: 'done',
            done: const Value(true),
            isPaused: const Value(false),
          ),
        );
  }

  // ------------------------------------------------------------ outbox

  Future<int> enqueueCheckIn({
    required String userId,
    required String contractId,
    required String commitmentId,
    required String commitmentTitle,
    required DateTime day,
  }) async {
    return _db
        .into(_db.outboxCheckins)
        .insert(
          OutboxCheckinsCompanion.insert(
            userId: userId,
            contractId: contractId,
            commitmentId: commitmentId,
            commitmentTitle: commitmentTitle,
            day: formatServerDay(day),
            createdAt: _nowIso(),
            status: 'pending',
          ),
        );
  }

  Future<List<OutboxCheckin>> pendingOutbox(String userId) async {
    return (_db.select(_db.outboxCheckins)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.localId)]))
        .get();
  }

  Future<void> markSent(int localId) {
    return (_db.delete(
      _db.outboxCheckins,
    )..where((t) => t.localId.equals(localId))).go();
  }

  Future<void> markFailed(int localId, String message) async {
    await (_db.update(
      _db.outboxCheckins,
    )..where((t) => t.localId.equals(localId))).write(
      OutboxCheckinsCompanion(
        status: const Value('failed'),
        errorMessage: Value(message),
      ),
    );
  }

  Future<void> deleteOutboxRow(int localId) {
    return markSent(localId);
  }

  Future<int> outboxCount(String userId) async {
    final List<OutboxCheckin> rows = await pendingOutbox(userId);
    return rows.length;
  }
}
