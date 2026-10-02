// Squad domain models. Feed rows carry ONLY what squad_feed() returns:
// display name, day number, today's kept/missed status, current streak, and
// missed count. Notes, letters, excuse free text, and commitment titles can
// never appear here by construction.

/// One squad the current user belongs to.
class Squad {
  const Squad({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  factory Squad.fromMap(Map<String, dynamic> map) {
    return Squad(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// One row of the squad_feed() RPC. Nulls mean "no active contract".
class SquadFeedRow {
  const SquadFeedRow({
    required this.memberUserId,
    required this.displayName,
    this.dayNumber,
    this.todayStatus,
    this.currentStreak,
    this.missedCount,
  });

  final String memberUserId;
  final String displayName;
  final int? dayNumber;
  final String? todayStatus;
  final int? currentStreak;
  final int? missedCount;

  bool get hasContract => dayNumber != null;

  factory SquadFeedRow.fromMap(Map<String, dynamic> map) {
    return SquadFeedRow(
      memberUserId: map['member_user_id'] as String,
      displayName: map['display_name'] as String,
      dayNumber: (map['day_number'] as num?)?.toInt(),
      todayStatus: map['today_status'] as String?,
      currentStreak: (map['current_streak'] as num?)?.toInt(),
      missedCount: (map['missed_count'] as num?)?.toInt(),
    );
  }
}

/// Invite codes are 6 uppercase alphanumeric chars (server check constraint).
bool isValidInviteCode(String value) {
  return RegExp(r'^[A-Z0-9]{6}$').hasMatch(value.trim().toUpperCase());
}

/// Normalizes user input to the canonical code shape.
String normalizeInviteCode(String value) => value.trim().toUpperCase();

/// The single preset nudge line (mirrors the server check constraint).
const String nudgePresetMessage = 'Your squad noticed. Today still counts.';
