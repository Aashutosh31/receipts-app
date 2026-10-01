// Contract repository: contracts, commitments, and pauses.
// UI layers must use this interface, never `Supabase.instance.client`.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ledger/domain/ledger_models.dart';
import '../domain/contract_draft.dart';
import '../domain/contract_models.dart';

/// Thrown for contract/pause problems with UI-safe text.
class ContractFailure implements Exception {
  const ContractFailure(this.message);

  final String message;

  @override
  String toString() => 'ContractFailure: $message';
}

abstract class ContractRepository {
  Future<List<Contract>> fetchContracts();
  Future<Contract?> fetchActiveContract();
  Future<List<Commitment>> fetchCommitments(String contractId);

  /// Atomically creates the contract plus 3-5 commitments via the
  /// `create_contract_with_commitments` RPC. Returns the new contract id.
  Future<String> createContract({
    required DateTime startDate,
    required ContractModeDto mode,
    required List<CommitmentDraft> commitments,
    String reason = 'initial contract lock',
  });

  Future<List<Pause>> fetchPauses(String contractId);
  Future<void> declarePause({
    required String contractId,
    required String type,
    required DateTime startDay,
  });
  Future<void> endPause({required String pauseId, required DateTime endDay});
}

class SupabaseContractRepository implements ContractRepository {
  SupabaseContractRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const ContractFailure('You are signed out. Sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<Contract>> fetchContracts() async {
    try {
      final List<dynamic> rows = await _client
          .from('contracts')
          .select()
          .order('created_at', ascending: false);
      return rows
          .map((dynamic e) => _contractFromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not load contracts: ${e.message}');
    }
  }

  @override
  Future<Contract?> fetchActiveContract() async {
    try {
      final dynamic row = await _client
          .from('contracts')
          .select()
          .eq('status', 'active')
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _contractFromMap(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not load your contract: ${e.message}');
    }
  }

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async {
    try {
      final List<dynamic> rows = await _client
          .from('commitments')
          .select()
          .eq('contract_id', contractId)
          .order('sort_order');
      return rows
          .map((dynamic e) => _commitmentFromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not load commitments: ${e.message}');
    }
  }

  @override
  Future<String> createContract({
    required DateTime startDate,
    required ContractModeDto mode,
    required List<CommitmentDraft> commitments,
    String reason = 'initial contract lock',
  }) async {
    try {
      final dynamic result = await _client.rpc(
        'create_contract_with_commitments',
        params: <String, dynamic>{
          'p_start_date': formatServerDay(startDate),
          'p_mode': mode.name,
          'p_commitments': commitments
              .map(
                (CommitmentDraft c) => <String, String>{
                  'title': c.title.trim(),
                  'target_time': c.targetTime.trim(),
                },
              )
              .toList(),
          'p_reason': reason,
        },
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not sign your contract: ${e.message}');
    }
  }

  @override
  Future<List<Pause>> fetchPauses(String contractId) async {
    try {
      final List<dynamic> rows = await _client
          .from('pauses')
          .select()
          .eq('contract_id', contractId)
          .order('start_day');
      return rows
          .map((dynamic e) => Pause.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not load pauses: ${e.message}');
    }
  }

  @override
  Future<void> declarePause({
    required String contractId,
    required String type,
    required DateTime startDay,
  }) async {
    try {
      await _client.from('pauses').insert(<String, dynamic>{
        'user_id': _userId,
        'contract_id': contractId,
        'type': type,
        'start_day': formatServerDay(startDay),
      });
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not declare pause: ${e.message}');
    }
  }

  @override
  Future<void> endPause({
    required String pauseId,
    required DateTime endDay,
  }) async {
    try {
      await _client
          .from('pauses')
          .update(<String, dynamic>{'end_day': formatServerDay(endDay)})
          .eq('id', pauseId);
    } on PostgrestException catch (e) {
      throw ContractFailure('Could not end pause: ${e.message}');
    }
  }

  Contract _contractFromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      mode: (map['mode'] as String) == 'hard'
          ? ContractModeDto.hard
          : ContractModeDto.kind,
      status: ContractStatus.values.firstWhere(
        (ContractStatus s) => s.name == (map['status'] as String),
        orElse: () => ContractStatus.active,
      ),
      kindRecoveriesUsed: (map['kind_recoveries_used'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Commitment _commitmentFromMap(Map<String, dynamic> map) {
    return Commitment(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      targetTime: map['target_time'] as String?,
      sortOrder: (map['sort_order'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      retiredAt: map['retired_at'] == null
          ? null
          : DateTime.parse(map['retired_at'] as String),
    );
  }
}
