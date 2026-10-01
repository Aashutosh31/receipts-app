/// Excuse analytics mirroring the SQL excuse counts.
///
/// Reasons are constrained in the DB to
/// tired/busy/unmotivated/forgot/other.
class ExcuseAnalytics {
  static const List<String> allowedReasons = <String>[
    'tired',
    'busy',
    'unmotivated',
    'forgot',
    'other',
  ];

  static Map<String, int> countByReason(Iterable<String> reasons) {
    final Map<String, int> counts = <String, int>{};
    for (final String reason in reasons) {
      if (!allowedReasons.contains(reason)) {
        continue;
      }
      counts[reason] = (counts[reason] ?? 0) + 1;
    }
    return counts;
  }

  static String? topExcuse(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }
    String top = counts.keys.first;
    for (final String key in counts.keys) {
      if (counts[key]! > counts[top]!) {
        top = key;
      }
    }
    return top;
  }
}
