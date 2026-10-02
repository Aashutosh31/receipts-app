// Offline-first local cache (drift/SQLite) plus the check-in outbox queue.
//
// Every cached row carries the owning user_id so device-sharing users can
// never read each other's cache. Code-generated part lives in
// local_database.g.dart (build_runner + drift_dev).
//
// See: https://drift.simonbinder.eu/docs/getting-started/
// See: https://pub.dev/packages/drift_flutter

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

/// Server snapshot of the active contract, for offline reading.
class CachedContracts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get mode => text()();
  TextColumn get status => text()();
  IntColumn get kindRecoveriesUsed => integer()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Server snapshot of commitments, including retired ones (retiredAt set).
class CachedCommitments extends Table {
  TextColumn get id => text()();
  TextColumn get contractId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get targetTime => text().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get retiredAt => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Server snapshot of get_ledger() rows, plus optimistic local done rows.
class CachedLedgerEntries extends Table {
  TextColumn get key => text()();
  TextColumn get userId => text()();
  TextColumn get contractId => text()();
  TextColumn get commitmentId => text()();
  TextColumn get title => text()();
  TextColumn get day => text()();
  TextColumn get status => text()();
  BoolColumn get done => boolean().nullable()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

/// Server snapshot of get_streak() for the offline header.
class CachedStreaks extends Table {
  TextColumn get contractId => text()();
  TextColumn get userId => text()();
  IntColumn get currentStreak => integer()();
  IntColumn get recoveriesUsed => integer()();
  TextColumn get mode => text()();
  TextColumn get today => text()();
  TextColumn get asOf => text()();

  @override
  Set<Column> get primaryKey => {contractId, userId};
}

/// Offline check-in queue. Failed rows stay visible with the server's own
/// rejection message until the user explicitly dismisses them: nothing is
/// ever silently dropped.
class OutboxCheckins extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get contractId => text()();
  TextColumn get commitmentId => text()();
  TextColumn get commitmentTitle => text()();
  TextColumn get day => text()();
  TextColumn get createdAt => text()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
}

@DriftDatabase(
  tables: [
    CachedContracts,
    CachedCommitments,
    CachedLedgerEntries,
    CachedStreaks,
    OutboxCheckins,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production opener: one SQLite file in the app documents directory.
  /// See: https://pub.dev/packages/drift_flutter
  AppDatabase.defaults() : super(driftDatabase(name: 'receipts_cache'));

  @override
  int get schemaVersion => 1;
}
