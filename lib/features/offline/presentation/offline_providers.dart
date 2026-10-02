// Offline-first providers: drift database, connectivity, cached views,
// outbox, and sync triggers. Sync is best-effort background work; screens
// never depend on its result.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/streak_logic.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../data/local_cache.dart';
import '../data/local_database.dart';
import '../data/sync_repository.dart';
import '../domain/offline_models.dart';

export '../domain/offline_models.dart';

final appDatabaseProvider = Provider<AppDatabase>((Ref ref) {
  final AppDatabase db = AppDatabase.defaults();
  ref.onDispose(() => db.close());
  return db;
});

final localCacheProvider = Provider<LocalCache>(
  (Ref ref) => LocalCache(ref.watch(appDatabaseProvider)),
);

final syncRepositoryProvider = Provider<SyncRepository>(
  (Ref ref) => SupabaseSyncRepository(
    cache: ref.watch(localCacheProvider),
    ledger: ref.watch(ledgerRepositoryProvider),
    contracts: ref.watch(contractRepositoryProvider),
  ),
);

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (Ref ref) => Connectivity().onConnectivityChanged,
);

/// True when the device can reach the internet. Defaults to online while
/// the first check is pending so the app never flashes an offline UI.
final onlineProvider = StreamProvider<bool>((Ref ref) async* {
  final Connectivity connectivity = Connectivity();
  yield isOnlineResult(await connectivity.checkConnectivity());
  await for (final List<ConnectivityResult> results
      in connectivity.onConnectivityChanged) {
    yield isOnlineResult(results);
  }
});

/// Runs the outbox + cache refresh for the current user. Watched (not read)
/// by Gate/Today so it fires on app open; invalidated on reconnect,
/// pull-to-refresh, and after mutations.
final syncNowProvider = FutureProvider.autoDispose<SyncReport?>((
  Ref ref,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  return ref.watch(syncRepositoryProvider).syncNow(userId: userId);
});

final outboxProvider = FutureProvider.autoDispose<List<OutboxCheckin>>((
  Ref ref,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return <OutboxCheckin>[];
  }
  return ref.watch(localCacheProvider).pendingOutbox(userId);
});

final cachedLedgerProvider = FutureProvider.autoDispose
    .family<List<LedgerEntry>, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <LedgerEntry>[];
      }
      final LocalCache cache = ref.watch(localCacheProvider);
      final Contract? contract = await cache.readContract(userId);
      if (contract == null || contract.id != contractId) {
        return <LedgerEntry>[];
      }
      return cache.readLedger(userId, contractId);
    });

/// Offline-readable Today view built purely from cache. Streak and day
/// number are computed locally and labeled approximate: the server remains
/// the judge of every record.
final cachedTodayProvider = FutureProvider.autoDispose
    .family<CachedTodayView?, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return null;
      }
      final LocalCache cache = ref.watch(localCacheProvider);
      final Contract? contract = await cache.readContract(userId);
      if (contract == null || contract.id != contractId) {
        return null;
      }
      final List<LedgerEntry> ledger = await cache.readLedger(
        userId,
        contractId,
      );
      final List<OutboxCheckin> outbox = await cache.pendingOutbox(userId);
      final DateTime deviceToday = DateTime.now();
      final DateTime today = DateTime.utc(
        deviceToday.year,
        deviceToday.month,
        deviceToday.day,
      );
      final Set<String> queued = outbox
          .where(
            (OutboxCheckin row) =>
                row.status == 'pending' && row.day == formatServerDay(today),
          )
          .map((OutboxCheckin row) => row.commitmentId)
          .toSet();
      final List<CachedTodayRow> rows = <CachedTodayRow>[];
      for (final LedgerEntry entry in ledger.where(
        (LedgerEntry e) => e.day == today,
      )) {
        rows.add(
          CachedTodayRow(
            commitmentId: entry.commitmentId,
            title: entry.commitmentTitle,
            done: entry.done == true,
            queued: queued.contains(entry.commitmentId),
            paused: entry.isPaused,
          ),
        );
      }
      rows.sort(
        (CachedTodayRow a, CachedTodayRow b) => a.title.compareTo(b.title),
      );
      final ContractMode mode = contract.mode == ContractModeDto.hard
          ? ContractMode.hard
          : ContractMode.kind;
      final Map<DateTime, List<LedgerEntry>> byDay =
          <DateTime, List<LedgerEntry>>{};
      for (final LedgerEntry entry in ledger) {
        byDay.putIfAbsent(entry.day, () => <LedgerEntry>[]).add(entry);
      }
      final List<DateTime> days = byDay.keys.toList()..sort();
      final List<DailyStreakInput> walk = <DailyStreakInput>[];
      for (final DateTime day in days) {
        if (day.isAfter(today)) {
          continue;
        }
        final List<LedgerEntry> dayRows = byDay[day]!;
        if (dayRows.any((LedgerEntry e) => e.isPaused)) {
          walk.add(const DailyStreakInput(allDone: false, isPaused: true));
        } else if (dayRows.isNotEmpty) {
          walk.add(
            DailyStreakInput(
              allDone: dayRows.every((LedgerEntry e) => e.done == true),
            ),
          );
        }
      }
      final StreakResult streak = StreakLogic.calculateCurrentStreak(
        daysOldestFirst: walk,
        mode: mode,
      );
      final CachedStreak? stored = await cache.readStreak(userId, contractId);
      return CachedTodayView(
        dayNumber: dayNumber(contract.startDate, today),
        doneCount: rows.where((CachedTodayRow r) => r.done).length,
        totalCount: rows.length,
        streak: streak.currentStreak,
        isPaused: rows.any((CachedTodayRow r) => r.paused),
        rows: rows,
        asOf: stored?.asOf,
      );
    });
