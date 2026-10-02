// Riverpod providers for squads. User-scoped like every other data
// provider: the live auth user id is awaited first so cached rows can never
// cross users.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/squad_repository.dart';
import '../domain/squad_models.dart';

final squadRepositoryProvider = Provider<SquadRepository>(
  (Ref ref) => SupabaseSquadRepository(),
);

final mySquadsProvider = FutureProvider.autoDispose<List<Squad>>((
  Ref ref,
) async {
  final String? userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    return <Squad>[];
  }
  return ref.watch(squadRepositoryProvider).fetchMySquads();
});

final squadFeedProvider = FutureProvider.autoDispose
    .family<List<SquadFeedRow>, String>((Ref ref, String squadId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <SquadFeedRow>[];
      }
      return ref.watch(squadRepositoryProvider).fetchFeed(squadId);
    });

final nudgedTodayProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((Ref ref, String squadId) async {
      final String? userId = await ref.watch(currentUserIdProvider.future);
      if (userId == null) {
        return <String>{};
      }
      return ref.watch(squadRepositoryProvider).fetchNudgedToday(squadId);
    });
