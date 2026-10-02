// Pure excuse-analytics calculations for the Insights screen.
// Confronts with data, never insults the person.

import '../../excuse/domain/excuse_models.dart';

/// One calendar week bucket (Monday-Sunday) of excuse counts.
class WeekBucket {
  const WeekBucket({
    required this.weekStart,
    required this.label,
    required this.count,
  });

  final DateTime weekStart;
  final String label;
  final int count;
}

/// Aggregated excuse statistics for one contract.
class ExcuseStats {
  const ExcuseStats({
    required this.total,
    required this.byReason,
    required this.topReason,
    required this.topCount,
    required this.byWeekday,
    required this.byCommitment,
    required this.weeklyTrend,
  });

  final int total;
  final Map<String, int> byReason;
  final String? topReason;
  final int topCount;
  final Map<int, int> byWeekday;
  final Map<String, int> byCommitment;
  final List<WeekBucket> weeklyTrend;

  static const List<String> weekdayNames = <String>[
    'Mondays',
    'Tuesdays',
    'Wednesdays',
    'Thursdays',
    'Fridays',
    'Saturdays',
    'Sundays',
  ];

  /// Weekday (1=Monday..7=Sunday) carrying the most of [reason], or null.
  int? peakWeekdayFor(String reason, List<Excuse> excuses) {
    final Map<int, int> counts = <int, int>{};
    for (final Excuse e in excuses) {
      if (e.reason.name == reason) {
        counts[e.day.weekday] = (counts[e.day.weekday] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return null;
    }
    int best = counts.keys.first;
    for (final int day in counts.keys) {
      if (counts[day]! > counts[best]!) {
        best = day;
      }
    }
    return best;
  }
}

/// Builds statistics from filed excuses. [commitmentTitles] maps
/// commitment id to title for the per-commitment breakdown.
ExcuseStats computeExcuseStats(
  List<Excuse> excuses, {
  Map<String, String> commitmentTitles = const <String, String>{},
  DateTime? referenceToday,
}) {
  final Map<String, int> byReason = <String, int>{};
  final Map<int, int> byWeekday = <int, int>{};
  final Map<String, int> byCommitment = <String, int>{};
  for (final Excuse e in excuses) {
    byReason[e.reason.name] = (byReason[e.reason.name] ?? 0) + 1;
    byWeekday[e.day.weekday] = (byWeekday[e.day.weekday] ?? 0) + 1;
    final String label = commitmentTitles[e.commitmentId] ?? e.commitmentId;
    byCommitment[label] = (byCommitment[label] ?? 0) + 1;
  }
  String? top;
  int topCount = 0;
  for (final MapEntry<String, int> entry in byReason.entries) {
    if (entry.value > topCount) {
      top = entry.key;
      topCount = entry.value;
    }
  }
  return ExcuseStats(
    total: excuses.length,
    byReason: byReason,
    topReason: top,
    topCount: topCount,
    byWeekday: byWeekday,
    byCommitment: byCommitment,
    weeklyTrend: _weeklyTrend(excuses, referenceToday),
  );
}

List<WeekBucket> _weeklyTrend(List<Excuse> excuses, DateTime? referenceToday) {
  if (excuses.isEmpty) {
    return const <WeekBucket>[];
  }
  final List<Excuse> sorted = excuses.toList()
    ..sort((Excuse a, Excuse b) => a.day.compareTo(b.day));
  final DateTime firstMonday = _mondayOf(sorted.first.day);
  final DateTime end = referenceToday ?? sorted.last.day;
  final DateTime lastMonday = _mondayOf(end);
  final Map<DateTime, int> counts = <DateTime, int>{};
  for (final Excuse e in excuses) {
    final DateTime monday = _mondayOf(e.day);
    counts[monday] = (counts[monday] ?? 0) + 1;
  }
  final List<WeekBucket> buckets = <WeekBucket>[];
  DateTime cursor = firstMonday;
  while (!cursor.isAfter(lastMonday)) {
    buckets.add(
      WeekBucket(
        weekStart: cursor,
        label: _shortLabel(cursor),
        count: counts[cursor] ?? 0,
      ),
    );
    cursor = cursor.add(const Duration(days: 7));
  }
  return buckets;
}

DateTime _mondayOf(DateTime day) {
  final DateTime date = DateTime.utc(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortLabel(DateTime monday) {
  return '${_months[monday.month - 1]} ${monday.day}';
}

/// One-line insight generated from the data. Direct, never cruel.
String insightLine(ExcuseStats stats, List<Excuse> excuses) {
  final String? top = stats.topReason;
  if (top == null || stats.total == 0) {
    return 'No excuses on record. The mirror is clean — keep it that way.';
  }
  final String base =
      'Your #1 excuse is \'$top\' '
      '(${stats.topCount} time${stats.topCount == 1 ? '' : 's'}).';
  final int? peak = stats.peakWeekdayFor(top, excuses);
  if (peak != null) {
    final int peakCount = excuses
        .where((Excuse e) => e.reason.name == top && e.day.weekday == peak)
        .length;
    if (peakCount >= 2 && peakCount * 2 >= stats.topCount) {
      return '$base $peakCount of them were on '
          '${ExcuseStats.weekdayNames[peak - 1]}.';
    }
  }
  String? peakCommitment;
  int peakCommitmentCount = 0;
  for (final MapEntry<String, int> entry in stats.byCommitment.entries) {
    if (entry.value > peakCommitmentCount) {
      peakCommitment = entry.key;
      peakCommitmentCount = entry.value;
    }
  }
  if (peakCommitment != null &&
      peakCommitmentCount >= 2 &&
      peakCommitmentCount * 2 >= stats.total) {
    return '$base Most often on \'$peakCommitment\'.';
  }
  return base;
}
