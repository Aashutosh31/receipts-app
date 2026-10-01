// Riverpod providers for authentication. Repository access stays behind
// these providers so UI and router never touch Supabase directly.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => SupabaseAuthRepository(),
);

final authChangesProvider = StreamProvider<AuthState>(
  (Ref ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Notifies go_router's refreshListenable whenever auth state changes.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<AuthState> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authRefreshProvider = Provider<AuthRefreshNotifier>((Ref ref) {
  final AuthRefreshNotifier notifier = AuthRefreshNotifier(
    ref.watch(authRepositoryProvider).authStateChanges,
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});
