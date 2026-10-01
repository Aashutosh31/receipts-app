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

/// One row of the public.pauses table: a declared sick/injury pause.
/// Recorded visibly in the Ledger; never breaks the streak.
class Pause {
  const Pause({
    required this.id,
    required this.contractId,
    required this.userId,
    required this.type,
    required this.startDay,
    this.endDay,
    required this.createdAt,
  });

  final String id;
  final String contractId;
  final String userId;

  /// 'sick' or 'injury', matching the database check constraint.
  final String type;
  final DateTime startDay;
  final DateTime? endDay;
  final DateTime createdAt;

  bool get isOpen => endDay == null;

  bool covers(DateTime day) {
    final DateTime target = DateTime.utc(day.year, day.month, day.day);
    final DateTime start = DateTime.utc(
      startDay.year,
      startDay.month,
      startDay.day,
    );
    if (target.isBefore(start)) {
      return false;
    }
    if (endDay == null) {
      return true;
    }
    final DateTime end = DateTime.utc(endDay!.year, endDay!.month, endDay!.day);
    return !target.isAfter(end);
  }

  factory Pause.fromMap(Map<String, dynamic> map) {
    return Pause(
      id: map['id'] as String,
      contractId: map['contract_id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      startDay: DateTime.parse(map['start_day'] as String).toUtc(),
      endDay: map['end_day'] == null
          ? null
          : DateTime.parse(map['end_day'] as String).toUtc(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
