// Riverpod providers for future-self letters. User-scoped like every
// other data provider: the live auth user id is awaited first so cached
// letters can never cross users.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/letter_repository.dart';
import '../domain/letter_models.dart';

final letterRepositoryProvider = Provider<LetterRepository>(
  (Ref ref) => SupabaseLetterRepository(),
);

final lettersProvider = FutureProvider.autoDispose
    .family<List<LetterEntry>, String>((Ref ref, String contractId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <LetterEntry>[];
      }
      return ref.watch(letterRepositoryProvider).fetchLetters(contractId);
    });
