// Authentication repository. UI + router use this interface;
// only the Supabase implementation below touches the Supabase client.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown for auth problems with a message safe to show in the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  Session? get currentSession;
  User? get currentUser;

  /// Returns true when a session was created immediately. False means the
  /// account was created but email confirmation is still pending.
  Future<bool> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();

  /// Deletes the caller's account server-side via the delete-account Edge
  /// Function (service role key stays on the server). The caller's session
  /// is dead afterwards; callers must sign out and wipe local data next.
  Future<void> deleteAccount();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.session != null;
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    } catch (_) {
      throw const AuthFailure(
        'Something went wrong. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e.message));
    } catch (_) {
      throw const AuthFailure(
        'Something went wrong. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AuthFailure('Sign out failed. Try again.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final FunctionResponse response = await _client.functions.invoke(
        'delete-account',
      );
      if (response.status != 200) {
        throw AuthFailure(
          'Delete failed (server said ${response.status}). Try again.',
        );
      }
    } on FunctionException catch (e) {
      if (e.status == 401) {
        throw const AuthFailure('You are signed out. Sign in again.');
      }
      throw const AuthFailure(
        'Delete failed. Check your connection and try again.',
      );
    } catch (_) {
      throw const AuthFailure(
        'Delete failed. Check your connection and try again.',
      );
    }
  }

  /// Maps Supabase error text to plain, honest UI copy.
  static String _friendly(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Try again.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'That email already has an account. Sign in instead.';
    }
    if (lower.contains('password')) {
      return 'That password does not meet the requirements. '
          'Use at least 6 characters.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'That email address does not look right.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email first, then sign in.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    return message;
  }
}
