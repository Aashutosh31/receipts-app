// Riverpod providers for the ledger, streak, excuses, and pending excuses.
//
// User-scoped like the contract providers: each awaits the live
// authenticated user id, so auth transitions always refetch and cached rows
// never cross users. autoDispose drops caches with their last listener.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../excuse/data/excuse_repository.dart';
import '../../excuse/domain/excuse_models.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger_models.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (Ref ref) => SupabaseLedgerRepository(),
);

final excuseRepositoryProvider = Provider<ExcuseRepository>(
  (Ref ref) => SupabaseExcuseRepository(),
);

final ledgerProvider = FutureProvider.autoDispose
    .family<List<LedgerEntry>, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <LedgerEntry>[];
      }
      return ref.watch(ledgerRepositoryProvider).fetchLedger(contractId);
    });

final streakProvider = FutureProvider.autoDispose.family<StreakInfo, String>((
  Ref ref,
  String contractId,
) async {
  // No empty streak exists; signed-out callers are routed away before
  // this can surface (auth guard), so failing fast is correct here.
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    throw StateError('signed out');
  }
  return ref.watch(ledgerRepositoryProvider).fetchStreak(contractId);
});

final excusesProvider = FutureProvider.autoDispose<List<Excuse>>((
  Ref ref,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return <Excuse>[];
  }
  return ref.watch(excuseRepositoryProvider).fetchExcuses();
});

/// Missed check-ins inside the 48-hour window with no excuse filed yet.
/// Empty while any input is still loading.
final pendingExcusesProvider = Provider.autoDispose
    .family<List<PendingExcuse>, String>((Ref ref, String contractId) {
      final List<LedgerEntry>? ledger = ref
          .watch(ledgerProvider(contractId))
          .maybeWhen(data: (List<LedgerEntry> v) => v, orElse: () => null);
      final List<Excuse>? excuses = ref
          .watch(excusesProvider)
          .maybeWhen(data: (List<Excuse> v) => v, orElse: () => null);
      final StreakInfo? streak = ref
          .watch(streakProvider(contractId))
          .maybeWhen(data: (StreakInfo v) => v, orElse: () => null);
      if (ledger == null || excuses == null || streak == null) {
        return const <PendingExcuse>[];
      }
      final Set<String> ids = ledger
          .map((LedgerEntry e) => e.commitmentId)
          .toSet();
      return pendingExcuses(
        missed: ledger
            .where((LedgerEntry e) => e.status == 'missed')
            .map(
              (LedgerEntry e) => (
                commitmentId: e.commitmentId,
                title: e.commitmentTitle,
                day: e.day,
              ),
            )
            .toList(),
        filed: excuses
            .where((Excuse x) => ids.contains(x.commitmentId))
            .toList(),
        serverToday: streak.today,
      );
    });
