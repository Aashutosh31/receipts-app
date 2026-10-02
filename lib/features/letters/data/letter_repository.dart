// Letter repository: bodies flow only through the get_letters() RPC, which
// returns null while a milestone is locked. UI never selects letter bodies
// directly (column grants forbid it).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/letter_models.dart';

/// Thrown for letter problems with UI-safe text.
class LetterFailure implements Exception {
  const LetterFailure(this.message);

  final String message;

  @override
  String toString() => 'LetterFailure: $message';
}

abstract class LetterRepository {
  Future<List<LetterEntry>> fetchLetters(String contractId);

  /// Writes one milestone letter. Allowed any time before its unlock; the
  /// database unique constraint keeps one letter per milestone.
  Future<void> writeLetter({
    required String contractId,
    required int unlockDayNumber,
    required String body,
  });
}

class SupabaseLetterRepository implements LetterRepository {
  SupabaseLetterRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const LetterFailure('You are signed out. Sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<LetterEntry>> fetchLetters(String contractId) async {
    try {
      final dynamic data = await _client.rpc(
        'get_letters',
        params: <String, dynamic>{'p_contract_id': contractId},
      );
      final List<dynamic> rows = data as List<dynamic>;
      final List<LetterEntry> letters =
          rows
              .map(
                (dynamic e) => LetterEntry.fromMap(e as Map<String, dynamic>),
              )
              .toList()
            ..sort(
              (LetterEntry a, LetterEntry b) =>
                  a.unlockDayNumber.compareTo(b.unlockDayNumber),
            );
      return letters;
    } on PostgrestException catch (e) {
      throw LetterFailure('Could not load letters: ${e.message}');
    }
  }

  @override
  Future<void> writeLetter({
    required String contractId,
    required int unlockDayNumber,
    required String body,
  }) async {
    final String? problem = validateLetterBody(body);
    if (problem != null) {
      throw LetterFailure(problem);
    }
    try {
      await _client.from('letters').insert(<String, dynamic>{
        'user_id': _userId,
        'contract_id': contractId,
        'unlock_day_number': unlockDayNumber,
        'body': body.trim(),
      });
    } on PostgrestException catch (e) {
      throw LetterFailure('Could not save the letter: ${e.message}');
    }
  }
}
