// Shared test fakes: a controllable auth repository. The stream replays the
// current session on listen (like gotrue's INITIAL_SESSION), then live
// events, so providers under test settle without real Supabase.

import 'dart:async';

import 'package:receipts/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session sessionFor(String userId) {
  final User user = User(
    id: userId,
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: DateTime.utc(2026, 10, 1).toIso8601String(),
  );
  return Session(accessToken: 'token-$userId', tokenType: 'bearer', user: user);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({String? initialUserId})
    : session = initialUserId == null ? null : sessionFor(initialUserId);

  final StreamController<AuthState> events =
      StreamController<AuthState>.broadcast();

  Session? session;

  void signInAs(String userId) {
    session = sessionFor(userId);
    events.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  void signOutAs() {
    session = null;
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Stream<AuthState> get authStateChanges async* {
    yield AuthState(AuthChangeEvent.initialSession, session);
    yield* events.stream;
  }

  @override
  Session? get currentSession => session;

  @override
  User? get currentUser => session?.user;

  @override
  Future<bool> signUp({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError();
  }
}
