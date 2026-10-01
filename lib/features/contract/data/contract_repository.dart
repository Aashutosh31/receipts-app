import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/contract_models.dart';

/// Repository wrapping all Supabase calls for contracts.
/// UI layers must use this class, never `Supabase.instance.client` directly.
class ContractRepository {
  ContractRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Contract>> fetchContracts() async {
    final List<dynamic> rows = await _client
        .from('contracts')
        .select()
        .order('created_at', ascending: false);
    return rows
        .map((dynamic e) => _fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Contract _fromMap(Map<String, dynamic> map) {
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
}
