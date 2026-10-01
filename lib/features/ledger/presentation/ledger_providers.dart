// Riverpod providers for the ledger, streak, excuses, and pending excuses.

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final ledgerProvider = FutureProvider.family<List<LedgerEntry>, String>(
  (Ref ref, String contractId) =>
      ref.watch(ledgerRepositoryProvider).fetchLedger(contractId),
);

final streakProvider = FutureProvider.family<StreakInfo, String>(
  (Ref ref, String contractId) =>
      ref.watch(ledgerRepositoryProvider).fetchStreak(contractId),
);

final excusesProvider = FutureProvider<List<Excuse>>(
  (Ref ref) => ref.watch(excuseRepositoryProvider).fetchExcuses(),
);

/// Missed check-ins inside the 48-hour window with no excuse filed yet.
/// Empty while any input is still loading.
final pendingExcusesProvider = Provider.family<List<PendingExcuse>, String>((
  Ref ref,
  String contractId,
) {
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
  final Set<String> ids = ledger.map((LedgerEntry e) => e.commitmentId).toSet();
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
    filed: excuses.where((Excuse x) => ids.contains(x.commitmentId)).toList(),
    serverToday: streak.today,
  );
});
