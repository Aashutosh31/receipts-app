// Riverpod providers for contracts, commitments, and pauses.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contract_repository.dart';
import '../domain/contract_models.dart';

final contractRepositoryProvider = Provider<ContractRepository>(
  (Ref ref) => SupabaseContractRepository(),
);

final activeContractProvider = FutureProvider<Contract?>(
  (Ref ref) => ref.watch(contractRepositoryProvider).fetchActiveContract(),
);

final commitmentsProvider = FutureProvider.family<List<Commitment>, String>(
  (Ref ref, String contractId) =>
      ref.watch(contractRepositoryProvider).fetchCommitments(contractId),
);

final pausesProvider = FutureProvider.family<List<Pause>, String>(
  (Ref ref, String contractId) =>
      ref.watch(contractRepositoryProvider).fetchPauses(contractId),
);
