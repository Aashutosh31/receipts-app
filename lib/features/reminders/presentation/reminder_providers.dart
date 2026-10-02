// Reminder providers: service access, settings, refresh orchestration, and
// live status. Refresh is best-effort background work: failures never break
// screens (the ledger remains the source of truth).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../data/notification_service.dart';
import '../data/settings_store.dart';
import '../domain/message_engine.dart';
import '../domain/reminder_plan.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (Ref ref) => LocalNotificationService(),
);

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (Ref ref) => SharedPreferences.getInstance(),
);

final settingsStoreProvider = FutureProvider.autoDispose<ReminderSettingsStore>(
  (Ref ref) async {
    final SharedPreferences prefs = await ref.watch(sharedPrefsProvider.future);
    final String? userId = await ref.watch(currentUserIdProvider.future);
    return ReminderSettingsStore(prefs, userId: userId);
  },
);

final reminderSettingsProvider = FutureProvider.autoDispose<ReminderSettings>((
  Ref ref,
) async {
  final ReminderSettingsStore store = await ref.watch(
    settingsStoreProvider.future,
  );
  return store.load();
});

/// Cancels everything and schedules the next 7 days. Runs on every app open
/// (covers app updates, reboots via the plugin boot receiver plus window
/// extension here, timezone changes, and contract edits).
final reminderRefreshProvider = FutureProvider.autoDispose<void>((
  Ref ref,
) async {
  try {
    final Contract? contract = await ref.watch(activeContractProvider.future);
    if (contract == null) {
      return;
    }
    final NotificationService service = ref.watch(notificationServiceProvider);
    if (service is LocalNotificationService && !service.isReady) {
      await service.init();
    }
    final ReminderSettings settings = await ref.watch(
      reminderSettingsProvider.future,
    );
    final List<Commitment> commitments = await ref.watch(
      commitmentsProvider(contract.id).future,
    );
    final List<LedgerEntry> ledger = await ref.watch(
      ledgerProvider(contract.id).future,
    );
    final StreakInfo streak = await ref.watch(
      streakProvider(contract.id).future,
    );
    final List<Excuse> excuses = await ref.watch(excusesProvider.future);
    final List<Pause> pauses = await ref.watch(
      pausesProvider(contract.id).future,
    );
    await refreshReminders(
      service: service,
      settings: settings,
      contract: contract,
      commitments: commitments,
      ledger: ledger,
      streak: streak,
      excuses: excuses,
      pauses: pauses,
      now: DateTime.now(),
    );
  } catch (_) {
    return;
  }
});

/// Live status for the Settings screen.
class ReminderStatus {
  const ReminderStatus({
    required this.enabled,
    required this.exact,
    required this.pending,
  });

  final bool enabled;
  final bool exact;
  final int pending;
}

final reminderStatusProvider = FutureProvider.autoDispose<ReminderStatus>((
  Ref ref,
) async {
  final NotificationService service = ref.watch(notificationServiceProvider);
  if (service is LocalNotificationService && !service.isReady) {
    return const ReminderStatus(enabled: false, exact: false, pending: 0);
  }
  try {
    return ReminderStatus(
      enabled: await service.notificationsEnabled(),
      exact: await service.canScheduleExact(),
      pending: await service.pendingCount(),
    );
  } catch (_) {
    return const ReminderStatus(enabled: false, exact: false, pending: 0);
  }
});

String _shortTime(String? value) {
  if (value == null || value.length < 5) {
    return '';
  }
  return value.substring(0, 5);
}

String _hhmm(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

DateTime _dayOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

/// Core scheduling routine, kept free of Riverpod for testability of its
/// inputs (callers gather data; pure plan/message helpers do the math).
Future<RefreshReport> refreshReminders({
  required NotificationService service,
  required ReminderSettings settings,
  required Contract contract,
  required List<Commitment> commitments,
  required List<LedgerEntry> ledger,
  required StreakInfo streak,
  required List<Excuse> excuses,
  required List<Pause> pauses,
  required DateTime now,
}) async {
  final bool enabled;
  try {
    enabled = await service.notificationsEnabled();
  } catch (_) {
    return const RefreshReport(scheduled: 0, exact: false, enabled: false);
  }
  await service.cancelAll();
  if (!enabled) {
    return const RefreshReport(scheduled: 0, exact: false, enabled: false);
  }
  bool exact = false;
  try {
    exact = await service.canScheduleExact();
  } catch (_) {
    exact = false;
  }

  final DateTime serverToday = _dayOnly(streak.today).toUtc();
  final Map<String, Set<DateTime>> doneBy = <String, Set<DateTime>>{};
  for (final LedgerEntry entry in ledger) {
    if (entry.done == true) {
      doneBy
          .putIfAbsent(entry.commitmentId, () => <DateTime>{})
          .add(_dayOnly(entry.day));
    }
  }
  final Set<DateTime> pausedDays = <DateTime>{};
  for (int offset = 0; offset < 7; offset++) {
    final DateTime day = DateTime.utc(
      serverToday.year,
      serverToday.month,
      serverToday.day,
    ).add(Duration(days: offset));
    for (final Pause pause in pauses) {
      if (pause.covers(day)) {
        pausedDays.add(day);
      }
    }
  }
  final List<CommitmentScheduleInput> inputs = commitments
      .map(
        (Commitment c) => CommitmentScheduleInput(
          id: c.id,
          title: c.title,
          targetTime: c.targetTime == null ? null : _shortTime(c.targetTime),
          enabled: settings.enabledFor(c.id),
          born: _dayOnly(c.createdAt),
          retired: c.retiredAt == null ? null : _dayOnly(c.retiredAt!),
        ),
      )
      .toList();
  final List<PlannedReminder> plan = planWeek(
    contractStart: _dayOnly(contract.startDate),
    contractEnd: _dayOnly(contract.endDate),
    serverToday: serverToday,
    commitments: inputs,
    doneDaysByCommitment: doneBy,
    pausedDays: pausedDays,
    quiet: settings.quietHours,
  );

  final List<Excuse> sortedExcuses = excuses.toList()
    ..sort((Excuse a, Excuse b) => b.day.compareTo(a.day));
  final String? latestExcuse = sortedExcuses.isEmpty
      ? null
      : sortedExcuses.first.reason.name;

  int scheduled = 0;
  for (final PlannedReminder item in plan) {
    final ReminderContext ctx = _contextFor(
      item: item,
      contract: contract,
      ledger: ledger,
      streak: streak,
      excuses: excuses,
      settings: settings,
      latestExcuse: latestExcuse,
      now: now,
    );
    final ReminderMessage message = pickMessage(
      ctx,
      salt: formatServerDay(item.day),
    );
    final bool done = await service.schedule(
      id: item.id,
      localFireTime: item.fireAtLocal,
      title: message.title,
      body: message.body,
      exact: exact,
    );
    if (done) {
      scheduled += 1;
    }
  }
  return RefreshReport(scheduled: scheduled, exact: exact, enabled: true);
}

ReminderContext _contextFor({
  required PlannedReminder item,
  required Contract contract,
  required List<LedgerEntry> ledger,
  required StreakInfo streak,
  required List<Excuse> excuses,
  required ReminderSettings settings,
  required String? latestExcuse,
  required DateTime now,
}) {
  final DateTime serverToday = _dayOnly(streak.today).toUtc();
  final int dayNo = dayNumber(contract.startDate, item.day);
  switch (item.kind) {
    case ReminderKind.upcoming:
      return ReminderContext(
        kind: item.kind,
        title: item.title,
        targetTime: _shortTime(
          '${item.fireAtLocal.hour.toString().padLeft(2, '0')}:'
          '${item.fireAtLocal.minute.toString().padLeft(2, '0')}',
        ),
        nowTime: _hhmm(now),
        streak: streak.currentStreak,
        dayNumber: dayNo,
        lastExcuse: item.commitmentId == null
            ? latestExcuse
            : lastExcuseFor(excuses, item.commitmentId!),
        consecutiveMisses: item.commitmentId == null
            ? 0
            : consecutiveMisses(ledger, item.commitmentId!, serverToday),
        toneCap: settings.tone,
      );
    case ReminderKind.followUp:
      final DateTime target = item.fireAtLocal.subtract(followUpDelay);
      return ReminderContext(
        kind: item.kind,
        title: item.title,
        targetTime: _hhmm(target),
        nowTime: _hhmm(item.fireAtLocal),
        streak: streak.currentStreak,
        dayNumber: dayNo,
        lastExcuse: item.commitmentId == null
            ? latestExcuse
            : lastExcuseFor(excuses, item.commitmentId!),
        consecutiveMisses: item.commitmentId == null
            ? 0
            : consecutiveMisses(ledger, item.commitmentId!, serverToday),
        toneCap: settings.tone,
      );
    case ReminderKind.lastCall:
      final List<LedgerEntry> rows = ledger
          .where((LedgerEntry e) => e.day == _dayOnly(item.day).toUtc())
          .toList();
      final int done = rows.where((LedgerEntry e) => e.done == true).length;
      return ReminderContext(
        kind: item.kind,
        title: item.title,
        nowTime: _hhmm(now),
        streak: streak.currentStreak,
        dayNumber: dayNo,
        lastExcuse: latestExcuse,
        doneCount: done,
        totalCount: rows.length,
        toneCap: settings.tone,
      );
  }
}

class RefreshReport {
  const RefreshReport({
    required this.scheduled,
    required this.exact,
    required this.enabled,
  });

  final int scheduled;
  final bool exact;
  final bool enabled;
}

/// Cancels today's follow-up for one commitment after it is logged done.
Future<void> cancelFollowUps({
  required NotificationService service,
  required DateTime day,
  required String commitmentId,
}) {
  return service.cancel(
    reminderNotificationId(_dayOnly(day), commitmentId, ReminderKind.followUp),
  );
}
