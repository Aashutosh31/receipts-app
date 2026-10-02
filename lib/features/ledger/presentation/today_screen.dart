// Today screen: today's commitments with final Done actions, current
// streak, day number, and an honest status line. Submitting a check-in is
// permanent, so every Done tap goes through a confirm sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/data/contract_repository.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../contract/presentation/pause_sheet.dart';
import '../../contract/presentation/retire_sheet.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../excuse/presentation/excuse_sheet.dart';
import '../../letters/presentation/letter_providers.dart';
import '../../offline/presentation/offline_providers.dart';
import '../../offline/presentation/offline_today.dart';
import '../../offline/presentation/outbox_screen.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger_models.dart';
import 'ledger_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    // Reconnect: re-run sync, then reload network data.
    ref.listen(onlineProvider, (AsyncValue<bool>? prev, AsyncValue<bool> next) {
      final bool was =
          prev?.maybeWhen(data: (bool v) => v, orElse: () => true) ?? true;
      final bool isNow = next.maybeWhen(
        data: (bool v) => v,
        orElse: () => true,
      );
      if (!was && isNow) {
        ref.invalidate(syncNowProvider);
      }
    });
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            body: EmptyView(
              message: 'No contract yet. Sign one to start your 90 days.',
              action: FilledButton(
                onPressed: () => context.go('/contract/new'),
                child: const Text('Sign the Contract'),
              ),
            ),
            bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
          );
        }
        final bool online = ref
            .watch(onlineProvider)
            .maybeWhen(data: (bool v) => v, orElse: () => true);
        if (!online) {
          return OfflineTodayBody(contract: contract);
        }
        return _TodayBody(contract: contract);
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Loading…')),
      error: (Object error, StackTrace _) => Scaffold(
        body: ErrorView(
          message: _readable(error),
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}

class _TodayBody extends ConsumerStatefulWidget {
  const _TodayBody({required this.contract});

  final Contract contract;

  @override
  ConsumerState<_TodayBody> createState() => _TodayBodyState();
}

class _TodayBodyState extends ConsumerState<_TodayBody> {
  /// Signature of the pending set already presented, to avoid re-showing.
  String _shownPending = '';

  /// Permission intro is offered once per signed contract session.
  bool _permissionPrompted = false;

  /// Day-1 letter gate shown once until the day-0 letter exists.
  bool _letterGateShown = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Commitment>> commitments = ref.watch(
      commitmentsProvider(widget.contract.id),
    );
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(widget.contract.id),
    );
    final AsyncValue<List<LedgerEntry>> ledger = ref.watch(
      ledgerProvider(widget.contract.id),
    );
    final AsyncValue<List<Pause>> pauses = ref.watch(
      pausesProvider(widget.contract.id),
    );

    if (commitments.isLoading ||
        streak.isLoading ||
        ledger.isLoading ||
        pauses.isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading today…'));
    }
    final Object? error =
        commitments.asError?.error ??
        streak.asError?.error ??
        ledger.asError?.error ??
        pauses.asError?.error;
    if (error != null) {
      return Scaffold(
        body: ErrorView(
          message: _readable(error),
          onRetry: () {
            ref.invalidate(commitmentsProvider(widget.contract.id));
            ref.invalidate(streakProvider(widget.contract.id));
            ref.invalidate(ledgerProvider(widget.contract.id));
            ref.invalidate(pausesProvider(widget.contract.id));
          },
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
      );
    }

    final StreakInfo info = streak.requireValue;
    final DateTime today = info.today;
    final List<LedgerEntry> todays = ledger.requireValue
        .where((LedgerEntry e) => e.day == today)
        .toList();
    final int doneCount = todays
        .where((LedgerEntry e) => e.done == true)
        .length;
    final bool isPaused = todays.any((LedgerEntry e) => e.isPaused);
    final List<Pause> allPauses = pauses.requireValue;
    final Pause? openPause = allPauses.any((Pause p) => p.isOpen)
        ? allPauses.firstWhere((Pause p) => p.isOpen)
        : null;

    _maybeShowExcuses();
    _maybeShowPermissionGate();
    _maybeShowLetterGate();
    // Keep the 7-day reminder window fresh while Today is visible.
    // Best-effort: this UI never depends on the result.
    ref.watch(reminderRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(syncNowProvider);
            ref.invalidate(ledgerProvider(widget.contract.id));
            ref.invalidate(streakProvider(widget.contract.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const OutboxBanner(),
              _HeaderCard(
                contract: widget.contract,
                streak: info,
                doneCount: doneCount,
                totalCount: todays.length,
                isPaused: isPaused,
              ),
              if (isPaused) ...<Widget>[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Paused today — no check-in needed. '
                      'Rest, stay honest, come back.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (todays.isEmpty)
                const EmptyView(message: 'Nothing promised for today.')
              else
                for (final LedgerEntry entry in todays)
                  _CommitmentRow(
                    entry: entry,
                    enabled: !isPaused,
                    onDone: () => _submitDone(entry),
                    onRetire: () => _retireFlow(
                      entry,
                      info.currentStreak,
                      dayNumber(widget.contract.startDate, today),
                    ),
                  ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await showPauseSheet(
                    context: context,
                    ref: ref,
                    contract: widget.contract,
                    openPause: openPause,
                    serverToday: today,
                  );
                  if (!mounted) {
                    return;
                  }
                  ref.invalidate(reminderRefreshProvider);
                },
                child: Text(
                  openPause == null
                      ? 'Declare sick / injury pause'
                      : 'End pause (${openPause.type})',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
    );
  }

  void _maybeShowExcuses() {
    final List<PendingExcuse> pending = ref.read(
      pendingExcusesProvider(widget.contract.id),
    );
    if (pending.isEmpty) {
      _shownPending = '';
      return;
    }
    final String signature = pending
        .map(
          (PendingExcuse p) => '${p.commitmentId}|${p.day.toIso8601String()}',
        )
        .join(';');
    if (signature == _shownPending) {
      return;
    }
    _shownPending = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showPendingExcuses(
        context: context,
        ref: ref,
        contractId: widget.contract.id,
        pending: pending,
      );
    });
  }

  void _maybeShowPermissionGate() {
    // Watch so this rebuilds once settings finish loading.
    final settings = ref
        .watch(reminderSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (settings == null || settings.permissionAsked || _permissionPrompted) {
      return;
    }
    _permissionPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.push('/notifications/intro');
    });
  }

  void _maybeShowLetterGate() {
    // Watch so this rebuilds once letters finish loading.
    final letters = ref
        .watch(lettersProvider(widget.contract.id))
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (letters == null) {
      return;
    }
    final bool hasDayOne = letters.any((letter) => letter.unlockDayNumber == 0);
    if (hasDayOne) {
      _letterGateShown = false;
      return;
    }
    if (_letterGateShown) {
      return;
    }
    _letterGateShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.push('/letters/write?milestone=0&required=true');
    });
  }

  Future<void> _retireFlow(LedgerEntry entry, int streak, int dayNumber) async {
    await showRetireSheet(
      context: context,
      ref: ref,
      contract: widget.contract,
      commitmentId: entry.commitmentId,
      commitmentTitle: entry.commitmentTitle,
      streak: streak,
      dayNumber: dayNumber,
    );
  }

  Future<void> _submitDone(LedgerEntry entry) async {
    final bool confirmed = await showFinalConfirm(
      context: context,
      title: 'Log it?',
      body:
          '“${entry.commitmentTitle}” will be marked done for today. '
          'This is final — it cannot be edited or deleted later.',
      confirmLabel: 'Log done',
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await ref
          .read(ledgerRepositoryProvider)
          .submitCheckIn(commitmentId: entry.commitmentId, day: entry.day);
      // Drop today's follow-up immediately; the refresh below rebuilds the
      // whole window anyway. Best-effort: a stale follow-up is harmless.
      await cancelFollowUps(
        service: ref.read(notificationServiceProvider),
        day: entry.day,
        commitmentId: entry.commitmentId,
      ).catchError((Object _) {});
      ref.invalidate(ledgerProvider(widget.contract.id));
      ref.invalidate(streakProvider(widget.contract.id));
      ref.invalidate(reminderRefreshProvider);
    } on LedgerFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.contract,
    required this.streak,
    required this.doneCount,
    required this.totalCount,
    required this.isPaused,
  });

  final Contract contract;
  final StreakInfo streak;
  final int doneCount;
  final int totalCount;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int day = dayNumber(contract.startDate, streak.today);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${streak.currentStreak}',
              style: theme.textTheme.displayMedium,
              semanticsLabel: 'Current streak ${streak.currentStreak} days',
            ),
            Text('day streak', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(
              todayStatusLine(
                dayNumber: day,
                doneCount: doneCount,
                totalCount: totalCount,
                streak: streak.currentStreak,
                isPaused: isPaused,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (contract.mode == ContractModeDto.kind) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Kind Mode · ${streak.recoveriesUsed} of 2 recovery days used',
                style: theme.textTheme.bodySmall,
              ),
            ] else ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Hard Mode · any miss resets',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({
    required this.entry,
    required this.enabled,
    required this.onDone,
    required this.onRetire,
  });

  final LedgerEntry entry;
  final bool enabled;
  final VoidCallback onDone;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool done = entry.done == true;
    return Card(
      child: ListTile(
        title: Text(entry.commitmentTitle),
        subtitle: Text(done ? 'Done. On the record.' : 'Not yet logged today.'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (done)
              Icon(Icons.check_circle, color: theme.colorScheme.primary)
            else
              FilledButton.tonal(
                onPressed: enabled ? onDone : null,
                child: const Text('Done'),
              ),
            if (!done)
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (String value) {
                  if (value == 'retire') {
                    onRetire();
                  }
                },
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'retire',
                        child: Text('Retire…'),
                      ),
                    ],
              ),
          ],
        ),
      ),
    );
  }
}

String _readable(Object error) {
  if (error is ContractFailure) {
    return error.message;
  }
  if (error is LedgerFailure) {
    return error.message;
  }
  return 'Something went wrong loading today.';
}
