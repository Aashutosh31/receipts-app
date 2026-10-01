// Ledger repository: get_ledger / get_streak RPCs and check-in writes.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ledger_models.dart';

/// Thrown for ledger problems with UI-safe text.
class LedgerFailure implements Exception {
  const LedgerFailure(this.message);

  final String message;

  @override
  String toString() => 'LedgerFailure: $message';
}

abstract class LedgerRepository {
  Future<List<LedgerEntry>> fetchLedger(String contractId);
  Future<StreakInfo> fetchStreak(String contractId);

  /// Inserts a done check-in for [day]. Final: no edit or delete exists.
  Future<void> submitCheckIn({
    required String commitmentId,
    required DateTime day,
  });
}

class SupabaseLedgerRepository implements LedgerRepository {
  SupabaseLedgerRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const LedgerFailure('You are signed out. Sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<LedgerEntry>> fetchLedger(String contractId) async {
    try {
      final dynamic data = await _client.rpc(
        'get_ledger',
        params: <String, dynamic>{'p_contract_id': contractId},
      );
      final List<dynamic> rows = data as List<dynamic>;
      return rows
          .map((dynamic e) => LedgerEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw LedgerFailure('Could not load the ledger: ${e.message}');
    }
  }

  @override
  Future<StreakInfo> fetchStreak(String contractId) async {
    try {
      final dynamic data = await _client.rpc(
        'get_streak',
        params: <String, dynamic>{'p_contract_id': contractId},
      );
      final List<dynamic> rows = data as List<dynamic>;
      if (rows.isEmpty) {
        throw const LedgerFailure('No streak data returned.');
      }
      return StreakInfo.fromMap(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw LedgerFailure('Could not load the streak: ${e.message}');
    }
  }

  @override
  Future<void> submitCheckIn({
    required String commitmentId,
    required DateTime day,
  }) async {
    try {
      await _client.from('check_ins').insert(<String, dynamic>{
        'user_id': _userId,
        'commitment_id': commitmentId,
        'day': formatServerDay(day),
        'done': true,
      });
    } on PostgrestException catch (e) {
      throw LedgerFailure(e.message);
    }
  }
}
