// Offline view models: small immutable shapes built from cache rows.

/// One Today row rendered from cache.
class CachedTodayRow {
  const CachedTodayRow({
    required this.commitmentId,
    required this.title,
    required this.done,
    required this.queued,
    required this.paused,
  });

  final String commitmentId;
  final String title;
  final bool done;
  final bool queued;
  final bool paused;
}

/// The whole offline Today screen state. Numbers are computed locally from
/// cached rows and shown as approximate until the next sync.
class CachedTodayView {
  const CachedTodayView({
    required this.dayNumber,
    required this.doneCount,
    required this.totalCount,
    required this.streak,
    required this.isPaused,
    required this.rows,
    this.asOf,
  });

  final int dayNumber;
  final int doneCount;
  final int totalCount;
  final int streak;
  final bool isPaused;
  final List<CachedTodayRow> rows;

  /// ISO timestamp of the snapshot these numbers came from, if known.
  final String? asOf;
}
