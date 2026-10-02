// Riverpod providers for contracts, commitments, and pauses.
//
// Every provider below is user-scoped: it awaits the live authenticated
// user id first, so sign-out/sign-in always triggers a fresh query and a
// previous user's cached rows can never leak to another user. They are
// autoDispose so cached rows also die with their last listener.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/contract_repository.dart';
import '../domain/contract_models.dart';

final contractRepositoryProvider = Provider<ContractRepository>(
  (Ref ref) => SupabaseContractRepository(),
);

final activeContractProvider = FutureProvider.autoDispose<Contract?>((
  Ref ref,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return null;
  }
  return ref.watch(contractRepositoryProvider).fetchActiveContract();
});

final commitmentsProvider = FutureProvider.autoDispose
    .family<List<Commitment>, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <Commitment>[];
      }
      return ref.watch(contractRepositoryProvider).fetchCommitments(contractId);
    });

final pausesProvider = FutureProvider.autoDispose.family<List<Pause>, String>((
  Ref ref,
  String contractId,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return <Pause>[];
  }
  return ref.watch(contractRepositoryProvider).fetchPauses(contractId);
});

final contractChangesProvider = FutureProvider.autoDispose
    .family<List<ContractChange>, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <ContractChange>[];
      }
      return ref
          .watch(contractRepositoryProvider)
          .fetchContractChanges(contractId);
    });
