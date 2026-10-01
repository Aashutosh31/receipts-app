// Immutable contract-domain models. UI never calls Supabase directly;
// repositories in ../data wrap Supabase calls (AGENTS.md architecture).

enum ContractModeDto { hard, kind }

enum ContractStatus { active, completed, abandoned }

class Contract {
  const Contract({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.status,
    required this.kindRecoveriesUsed,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final ContractModeDto mode;
  final ContractStatus status;
  final int kindRecoveriesUsed;
  final DateTime createdAt;

  Contract copyWith({ContractStatus? status, int? kindRecoveriesUsed}) {
    return Contract(
      id: id,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      mode: mode,
      status: status ?? this.status,
      kindRecoveriesUsed: kindRecoveriesUsed ?? this.kindRecoveriesUsed,
      createdAt: createdAt,
    );
  }
}

class Commitment {
  const Commitment({
    required this.id,
    required this.contractId,
    required this.userId,
    required this.title,
    this.targetTime,
    required this.sortOrder,
    required this.createdAt,
    this.retiredAt,
  });

  final String id;
  final String contractId;
  final String userId;
  final String title;
  final String? targetTime;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? retiredAt;

  bool get isRetired => retiredAt != null;
}
