// Sync orchestration: outbox processing with honest rejection handling,
// plus cache refresh from the network repositories.
//
// Server-truth rule: the server judges every check-in against its own clock
// (same-day + 03:00 grace). An offline check-in that arrives late is
// REJECTED by the database trigger; the row is marked failed with the
// server's own message and kept visible until the user dismisses it.
// Nothing is ever silently dropped.

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../contract/data/contract_repository.dart';
import '../../contract/domain/contract_models.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../ledger/domain/ledger_models.dart';
import 'local_cache.dart';
import 'local_database.dart';

/// True when the device has a route that can reach the internet (wifi,
/// mobile, or ethernet). Bluetooth/VPN alone do not count.
bool isOnlineResult(List<ConnectivityResult> results) {
  return results.any(
    (ConnectivityResult r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet,
  );
}

class SyncReport {
  const SyncReport({
    required this.sent,
    required this.failed,
    required this.failedMessages,
    required this.cacheRefreshed,
  });

  final int sent;
  final int failed;
  final List<String> failedMessages;
  final bool cacheRefreshed;
}

abstract class SyncRepository {
  /// Processes the current user's outbox oldest-first, then refreshes the
  /// local cache from the network. Safe to call offline (outbox waits,
  /// cache untouched) and with no signed-in user (no-op).
  Future<SyncReport> syncNow({required String? userId});
  Future<void> dismissFailed(int localId);
}

class SupabaseSyncRepository implements SyncRepository {
  SupabaseSyncRepository({
    required this._cache,
    required this._ledger,
    required this._contracts,
  });

  final LocalCache _cache;
  final LedgerRepository _ledger;
  final ContractRepository _contracts;

  /// A duplicate-key rejection means the row already exists server-side
  /// (e.g. an earlier attempt succeeded but the response was lost), so it
  /// counts as sent rather than failed.
  static bool isDuplicateError(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('duplicate') ||
        lower.contains('already exists') ||
        lower.contains('23505') ||
        lower.contains('unique');
  }

  @override
  Future<SyncReport> syncNow({required String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return const SyncReport(
        sent: 0,
        failed: 0,
        failedMessages: <String>[],
        cacheRefreshed: false,
      );
    }
    int sent = 0;
    final List<String> failures = <String>[];
    final List<OutboxCheckin> rows = await _cache.pendingOutbox(userId);
    for (final OutboxCheckin row in rows) {
      if (row.status == 'failed') {
        // A failed row already carries the server's verdict; retrying the
        // same late check-in would fail identically. It waits for explicit
        // user dismissal instead of churning the server.
        failures.add(row.errorMessage ?? 'Rejected by the server.');
        continue;
      }
      try {
        await _ledger.submitCheckIn(
          commitmentId: row.commitmentId,
          day: parseServerDay(row.day),
        );
        await _cache.markSent(row.localId);
        sent += 1;
      } on LedgerFailure catch (e) {
        if (isDuplicateError(e.message)) {
          await _cache.markSent(row.localId);
          sent += 1;
        } else {
          await _cache.markFailed(row.localId, e.message);
          failures.add(e.message);
        }
      }
    }
    bool refreshed = false;
    try {
      final Contract? contract = await _contracts.fetchActiveContract();
      if (contract != null) {
        final commitments = await _contracts.fetchCommitments(contract.id);
        final ledger = await _ledger.fetchLedger(contract.id);
        final streak = await _ledger.fetchStreak(contract.id);
        await _cache.writeSnapshot(
          userId: userId,
          contract: contract,
          commitments: commitments,
          ledger: ledger,
          streak: streak,
        );
        refreshed = true;
      }
    } on ContractFailure {
      refreshed = false;
    } on LedgerFailure {
      refreshed = false;
    }
    return SyncReport(
      sent: sent,
      failed: failures.length,
      failedMessages: failures,
      cacheRefreshed: refreshed,
    );
  }

  @override
  Future<void> dismissFailed(int localId) {
    return _cache.deleteOutboxRow(localId);
  }
}
