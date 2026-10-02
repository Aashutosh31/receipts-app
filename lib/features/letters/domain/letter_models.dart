// Future-self letter models. Bodies come only from the get_letters() RPC,
// which returns null while locked; the app never reads letter bodies
// directly (column grants forbid it).

/// Milestone unlock days supported by the database check constraint.
const List<int> letterMilestones = <int>[0, 30, 60, 90];

class LetterEntry {
  const LetterEntry({
    required this.id,
    required this.unlockDayNumber,
    required this.unlockDate,
    required this.isUnlocked,
    this.body,
  });

  final String id;
  final int unlockDayNumber;
  final DateTime unlockDate;
  final bool isUnlocked;
  final String? body;

  factory LetterEntry.fromMap(Map<String, dynamic> map) {
    return LetterEntry(
      id: map['id'] as String,
      unlockDayNumber: (map['unlock_day_number'] as num).toInt(),
      unlockDate: DateTime.parse(map['unlock_date'] as String).toUtc(),
      isUnlocked: map['is_unlocked'] as bool,
      body: map['body'] as String?,
    );
  }
}

/// Whole days from server [today] until [unlockDate]. Zero or negative means
/// the date has arrived (the RPC's is_unlocked flag stays authoritative).
int countdownDays(DateTime unlockDate, DateTime serverToday) {
  final DateTime start = DateTime.utc(
    serverToday.year,
    serverToday.month,
    serverToday.day,
  );
  final DateTime end = DateTime.utc(
    unlockDate.year,
    unlockDate.month,
    unlockDate.day,
  );
  return end.difference(start).inDays;
}

/// Human label for a milestone card.
String milestoneLabel(int unlockDayNumber) {
  if (unlockDayNumber == 0) {
    return 'Day 1 letter';
  }
  return 'Day $unlockDayNumber letter';
}

/// Validates letter body text (database: 1..5000 chars).
String? validateLetterBody(String value) {
  if (value.trim().isEmpty) {
    return 'Write something first. Future you is waiting.';
  }
  if (value.trim().length > 5000) {
    return 'Too long — keep it under 5000 characters.';
  }
  return null;
}
