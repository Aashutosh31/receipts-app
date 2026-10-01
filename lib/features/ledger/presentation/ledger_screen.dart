// Ledger screen: all 90 days as a read-only grid. Tapping a day shows
// promised versus done per commitment. No edit controls anywhere.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/data/contract_repository.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger_models.dart';
import 'ledger_providers.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            body: EmptyView(
              message: 'No contract yet. Sign one to start your ledger.',
              action: FilledButton(
                onPressed: () => context.go('/contract/new'),
                child: const Text('Sign the Contract'),
              ),
            ),
            bottomNavigationBar: const ReceiptsNavBar(currentIndex: 1),
          );
        }
        return _LedgerBody(contract: contract);
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

class _LedgerBody extends ConsumerWidget {
  const _LedgerBody({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LedgerEntry>> ledger = ref.watch(
      ledgerProvider(contract.id),
    );
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(contract.id),
    );

    if (ledger.isLoading || streak.isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading ledger…'));
    }
    final Object? error = ledger.asError?.error ?? streak.asError?.error;
    if (error != null) {
      return Scaffold(
        body: ErrorView(
          message: _readable(error),
          onRetry: () {
            ref.invalidate(ledgerProvider(contract.id));
            ref.invalidate(streakProvider(contract.id));
          },
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 1),
      );
    }

    final List<LedgerEntry> entries = ledger.requireValue;
    final StreakInfo info = streak.requireValue;
    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ledger'),
          actions: const <Widget>[SignOutButton()],
        ),
        body: const EmptyView(
          message: 'No ledger rows yet. Check back after day one.',
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 1),
      );
    }

    final Map<DateTime, LedgerDay> byDay = <DateTime, LedgerDay>{
      for (final LedgerDay d in summarizeLedgerDays(entries, info.today))
        d.day: d,
    };
    final Map<DateTime, List<LedgerEntry>> rowsByDay =
        <DateTime, List<LedgerEntry>>{};
    for (final LedgerEntry e in entries) {
      rowsByDay.putIfAbsent(e.day, () => <LedgerEntry>[]).add(e);
    }

    final DateTime start = DateTime.utc(
      contract.startDate.year,
      contract.startDate.month,
      contract.startDate.day,
    );
    final List<DateTime> allDays = List<DateTime>.generate(
      90,
      (int i) => start.add(Duration(days: i)),
    );
    final int kept = byDay.values
        .where((LedgerDay d) => d.status == DayStatus.kept)
        .length;
    final int missed = byDay.values
        .where((LedgerDay d) => d.status == DayStatus.missed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ledgerProvider(contract.id));
            ref.invalidate(streakProvider(contract.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(
                '$kept kept · $missed missed · read-only, permanent',
                semanticsLabel:
                    '$kept days kept, $missed days missed. Read only.',
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  StatusChip(label: 'kept', color: Colors.green),
                  StatusChip(label: 'missed', color: Colors.red),
                  StatusChip(label: 'paused', color: Colors.grey),
                  StatusChip(label: 'upcoming', color: Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: allDays.length,
                itemBuilder: (BuildContext context, int index) {
                  final DateTime day = allDays[index];
                  final LedgerDay? summary = byDay[day];
                  return _DayCell(
                    day: day,
                    summary: summary,
                    isToday: day == info.today,
                    onTap: summary == null
                        ? null
                        : () => _showDay(
                            context,
                            day,
                            summary,
                            rowsByDay[day] ?? const <LedgerEntry>[],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 1),
    );
  }

  void _showDay(
    BuildContext context,
    DateTime day,
    LedgerDay summary,
    List<LedgerEntry> rows,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${formatServerDay(day)} · ${_dayLabel(summary.status)}',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final LedgerEntry row in rows)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(row.commitmentTitle),
                          trailing: Text(
                            _rowLabel(row),
                            style: TextStyle(
                              color: _rowColor(sheetContext, row),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.summary,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final LedgerDay? summary;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill;
    final String label;
    switch (summary?.status) {
      case DayStatus.kept:
        fill = Colors.green.withValues(alpha: 0.35);
        label = 'kept';
      case DayStatus.missed:
        fill = Colors.red.withValues(alpha: 0.35);
        label = 'missed';
      case DayStatus.paused:
        fill = Colors.grey.withValues(alpha: 0.35);
        label = 'paused';
      case DayStatus.upcoming:
      case null:
        fill = Colors.transparent;
        label = 'upcoming';
    }
    return Tooltip(
      message: '${formatServerDay(day)}: $label',
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(
              color: isToday ? scheme.primary : scheme.outline,
              width: isToday ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '${day.day}',
                semanticsLabel: '${formatServerDay(day)}, $label',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _dayLabel(DayStatus status) {
  return switch (status) {
    DayStatus.kept => 'kept',
    DayStatus.missed => 'missed',
    DayStatus.paused => 'paused',
    DayStatus.upcoming => 'upcoming',
  };
}

String _rowLabel(LedgerEntry row) {
  if (row.isPaused) {
    return 'Paused';
  }
  return switch (row.status) {
    'done' => 'Done',
    'promised' => 'Promised',
    _ => 'Missed',
  };
}

Color _rowColor(BuildContext context, LedgerEntry row) {
  return AppTheme.statusColor(row.done, paused: row.isPaused);
}

String _readable(Object error) {
  if (error is ContractFailure) {
    return error.message;
  }
  if (error is LedgerFailure) {
    return error.message;
  }
  return 'Something went wrong loading the ledger.';
}
