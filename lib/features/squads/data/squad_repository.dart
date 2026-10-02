// Squad repository: squads, membership via invite codes, feed, and nudges.
// Membership writes go through secure RPCs; reads rely on member-gated RLS.
// UI layers must use this interface, never `Supabase.instance.client`.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/squad_models.dart';

/// Thrown for squad problems with UI-safe text.
class SquadFailure implements Exception {
  const SquadFailure(this.message);

  final String message;

  @override
  String toString() => 'SquadFailure: $message';
}

abstract class SquadRepository {
  Future<List<Squad>> fetchMySquads();
  Future<({String id, String inviteCode})> createSquad(String name);
  Future<String> joinSquad(String inviteCode);
  Future<void> leaveSquad(String squadId);
  Future<List<SquadFeedRow>> fetchFeed(String squadId);
  Future<Set<String>> fetchNudgedToday(String squadId);
  Future<void> sendNudge({required String squadId, required String toUserId});
}

class SupabaseSquadRepository implements SquadRepository {
  SupabaseSquadRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Squad>> fetchMySquads() async {
    try {
      final List<dynamic> rows = await _client
          .from('squads')
          .select()
          .order('created_at');
      return rows
          .map((dynamic e) => Squad.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SquadFailure('Could not load squads: ${e.message}');
    }
  }

  @override
  Future<({String id, String inviteCode})> createSquad(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw const SquadFailure('Squad name must be 1-60 characters.');
    }
    try {
      final dynamic data = await _client.rpc(
        'create_squad',
        params: <String, dynamic>{'p_name': trimmed},
      );
      final List<dynamic> rows = data as List<dynamic>;
      final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
      return (
        id: row['id'] as String,
        inviteCode: row['invite_code'] as String,
      );
    } on PostgrestException catch (e) {
      throw SquadFailure('Could not create squad: ${e.message}');
    }
  }

  @override
  Future<String> joinSquad(String inviteCode) async {
    final String code = normalizeInviteCode(inviteCode);
    if (!isValidInviteCode(code)) {
      throw const SquadFailure(
        'That code does not look right (6 letters or digits).',
      );
    }
    try {
      final dynamic result = await _client.rpc(
        'join_squad',
        params: <String, dynamic>{'p_invite_code': code},
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw SquadFailure(e.message);
    }
  }

  @override
  Future<void> leaveSquad(String squadId) async {
    try {
      await _client.rpc(
        'leave_squad',
        params: <String, dynamic>{'p_squad_id': squadId},
      );
    } on PostgrestException catch (e) {
      throw SquadFailure('Could not leave squad: ${e.message}');
    }
  }

  @override
  Future<List<SquadFeedRow>> fetchFeed(String squadId) async {
    try {
      final dynamic data = await _client.rpc(
        'squad_feed',
        params: <String, dynamic>{'p_squad_id': squadId},
      );
      final List<dynamic> rows = data as List<dynamic>;
      return rows
          .map((dynamic e) => SquadFeedRow.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw SquadFailure('Could not load the squad feed: ${e.message}');
    }
  }

  @override
  Future<Set<String>> fetchNudgedToday(String squadId) async {
    try {
      final dynamic data = await _client.rpc(
        'my_nudges_today',
        params: <String, dynamic>{'p_squad_id': squadId},
      );
      final List<dynamic> rows = data as List<dynamic>;
      return rows
          .map(
            (dynamic e) => (e as Map<String, dynamic>)['to_user_id'] as String,
          )
          .toSet();
    } on PostgrestException catch (e) {
      throw SquadFailure('Could not load nudges: ${e.message}');
    }
  }

  @override
  Future<void> sendNudge({
    required String squadId,
    required String toUserId,
  }) async {
    try {
      await _client.rpc(
        'send_nudge',
        params: <String, dynamic>{
          'p_squad_id': squadId,
          'p_to_user_id': toUserId,
        },
      );
    } on PostgrestException catch (e) {
      throw SquadFailure(e.message);
    }
  }
}
