// Excuse repository: reading filed excuses and filing new ones.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/excuse_models.dart';

/// Thrown for excuse problems with UI-safe text.
class ExcuseFailure implements Exception {
  const ExcuseFailure(this.message);

  final String message;

  @override
  String toString() => 'ExcuseFailure: $message';
}

abstract class ExcuseRepository {
  Future<List<Excuse>> fetchExcuses();
  Future<void> fileExcuse({
    required String commitmentId,
    required DateTime day,
    required ExcuseReason reason,
    String? freeText,
  });
}

class SupabaseExcuseRepository implements ExcuseRepository {
  SupabaseExcuseRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const ExcuseFailure('You are signed out. Sign in again.');
    }
    return user.id;
  }

  static String _formatDay(DateTime day) {
    final String month = day.month.toString().padLeft(2, '0');
    final String date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  @override
  Future<List<Excuse>> fetchExcuses() async {
    try {
      final List<dynamic> rows = await _client
          .from('excuses')
          .select()
          .order('day');
      return rows
          .map((dynamic e) => Excuse.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ExcuseFailure('Could not load excuses: ${e.message}');
    }
  }

  @override
  Future<void> fileExcuse({
    required String commitmentId,
    required DateTime day,
    required ExcuseReason reason,
    String? freeText,
  }) async {
    try {
      await _client.from('excuses').insert(<String, dynamic>{
        'user_id': _userId,
        'commitment_id': commitmentId,
        'day': _formatDay(day),
        'reason': reason.name,
        'free_text': (freeText == null || freeText.trim().isEmpty)
            ? null
            : freeText.trim(),
      });
    } on PostgrestException catch (e) {
      throw ExcuseFailure(e.message);
    }
  }
}
