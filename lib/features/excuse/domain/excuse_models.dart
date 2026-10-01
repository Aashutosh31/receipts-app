// Pure excuse domain. Reason names match the public.excuse_reason enum.

/// Allowed reasons, matching the database enum exactly.
enum ExcuseReason { tired, busy, unmotivated, forgot, other }

/// One row of the public.excuses table.
class Excuse {
  const Excuse({
    required this.id,
    required this.commitmentId,
    required this.day,
    required this.reason,
    this.freeText,
  });

  final String id;
  final String commitmentId;
  final DateTime day;
  final ExcuseReason reason;
  final String? freeText;

  factory Excuse.fromMap(Map<String, dynamic> map) {
    return Excuse(
      id: map['id'] as String,
      commitmentId: map['commitment_id'] as String,
      day: DateTime.parse(map['day'] as String).toUtc(),
      reason: ExcuseReason.values.firstWhere(
        (ExcuseReason r) => r.name == (map['reason'] as String),
        orElse: () => ExcuseReason.other,
      ),
      freeText: map['free_text'] as String?,
    );
  }
}

/// A missed (commitment, day) that still needs a tagged excuse.
class PendingExcuse {
  const PendingExcuse({
    required this.commitmentId,
    required this.commitmentTitle,
    required this.day,
  });

  final String commitmentId;
  final String commitmentTitle;
  final DateTime day;
}

/// Finds missed check-ins that fall inside the 48-hour excuse window and
/// have no excuse filed yet. [serverToday] is the server-computed today.
/// Days are compared by calendar date: a miss counts while
/// `today - day <= 2`. The database trigger enforces the exact deadline.
List<PendingExcuse> pendingExcuses({
  required List<({String commitmentId, String title, DateTime day})> missed,
  required List<Excuse> filed,
  required DateTime serverToday,
}) {
  final DateTime today = DateTime.utc(
    serverToday.year,
    serverToday.month,
    serverToday.day,
  );
  final Set<String> filedKeys = filed
      .map((Excuse e) => '${e.commitmentId}|${e.day.toIso8601String()}')
      .toSet();
  final List<PendingExcuse> result = <PendingExcuse>[];
  for (final m in missed) {
    final DateTime day = DateTime.utc(m.day.year, m.day.month, m.day.day);
    if (!day.isBefore(today)) {
      continue;
    }
    if (today.difference(day).inDays > 2) {
      continue;
    }
    if (filedKeys.contains('${m.commitmentId}|${day.toIso8601String()}')) {
      continue;
    }
    result.add(
      PendingExcuse(
        commitmentId: m.commitmentId,
        commitmentTitle: m.title,
        day: day,
      ),
    );
  }
  result.sort((PendingExcuse a, PendingExcuse b) => a.day.compareTo(b.day));
  return result;
}
