// Insights screen: excuse analytics with plain-Flutter bar visuals.
// Respectful empty state until the contract is at least 7 days old.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/excuse_stats.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            body: EmptyView(
              message: 'No contract yet. Insights need a ledger first.',
              action: FilledButton(
                onPressed: () => context.go('/contract/new'),
                child: const Text('Sign the Contract'),
              ),
            ),
            bottomNavigationBar: const ReceiptsNavBar(currentIndex: 2),
          );
        }
        return _InsightsBody(contract: contract);
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Loading…')),
      error: (Object error, StackTrace _) => Scaffold(
        body: ErrorView(
          message: 'Something went wrong loading insights.',
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Excuse>> excuses = ref.watch(excusesProvider);
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(contract.id),
    );
    final AsyncValue<List<Commitment>> commitments = ref.watch(
      commitmentsProvider(contract.id),
    );
    if (excuses.isLoading || streak.isLoading || commitments.isLoading) {
      return const Scaffold(body: LoadingView(message: 'Reading the mirror…'));
    }
    final Object? error =
        excuses.asError?.error ??
        streak.asError?.error ??
        commitments.asError?.error;
    if (error != null) {
      return Scaffold(
        body: ErrorView(
          message: 'Could not load insights.',
          onRetry: () {
            ref.invalidate(excusesProvider);
            ref.invalidate(streakProvider(contract.id));
            ref.invalidate(commitmentsProvider(contract.id));
          },
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 2),
      );
    }
    final DateTime serverToday = streak.requireValue.today;
    final int age = dayNumber(contract.startDate, serverToday);
    if (age < 7) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          actions: const <Widget>[SignOutButton()],
        ),
        body: EmptyView(
          message:
              'Day $age of 90. The mirror needs a full week — '
              'come back on day 7.',
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 2),
      );
    }
    final Map<String, String> titles = <String, String>{
      for (final Commitment c in commitments.requireValue) c.id: c.title,
    };
    final ExcuseStats stats = computeExcuseStats(
      excuses.requireValue,
      commitmentTitles: titles,
      referenceToday: serverToday,
    );
    if (stats.total == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          actions: const <Widget>[SignOutButton()],
        ),
        body: const EmptyView(
          message: 'No excuses filed. Suspiciously clean — keep it that way.',
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 2),
      );
    }
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(excusesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    insightLine(stats, excuses.requireValue),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('Top excuses'),
              const SizedBox(height: 8),
              ..._sorted(stats.byReason).map(
                (MapEntry<String, int> e) =>
                    _BarRow(label: e.key, count: e.value, max: stats.topCount),
              ),
              const SizedBox(height: 24),
              _SectionTitle('By weekday'),
              const SizedBox(height: 8),
              ...List<MapEntry<int, int>>.generate(7, (int i) {
                final int weekday = i + 1;
                return MapEntry<int, int>(
                  weekday,
                  stats.byWeekday[weekday] ?? 0,
                );
              }).map(
                (MapEntry<int, int> e) => _BarRow(
                  label: ExcuseStats.weekdayNames[e.key - 1].replaceAll(
                    RegExp(r's$'),
                    '',
                  ),
                  count: e.value,
                  max: _maxCount(stats.byWeekday.values),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('By commitment'),
              const SizedBox(height: 8),
              ..._sorted(stats.byCommitment).map(
                (MapEntry<String, int> e) => _BarRow(
                  label: e.key,
                  count: e.value,
                  max: _maxCount(stats.byCommitment.values),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('Trend by week'),
              const SizedBox(height: 8),
              _WeekStrip(buckets: stats.weeklyTrend),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 2),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

List<MapEntry<String, int>> _sorted(Map<String, int> map) {
  final List<MapEntry<String, int>> entries = map.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
      final int byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries;
}

int _maxCount(Iterable<int> values) {
  int max = 0;
  for (final int v in values) {
    if (v > max) {
      max = v;
    }
  }
  return max;
}

/// Plain-Flutter horizontal bar: label, proportional fill, count.
class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.count, required this.max});

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double fraction = max == 0 ? 0 : count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: '$label: $count',
            ),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// Plain-Flutter weekly trend strip: one column per week.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.buckets});

  final List<WeekBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (buckets.isEmpty) {
      return const Text('No weeks yet.');
    }
    final int max = _maxCount(buckets.map((WeekBucket b) => b.count));
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final WeekBucket bucket in buckets)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${bucket.count}',
                      style: theme.textTheme.labelSmall,
                      semanticsLabel:
                          'Week of ${bucket.label}: ${bucket.count} excuses',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: max == 0 ? 4 : 4 + 76 * (bucket.count / max),
                      decoration: BoxDecoration(
                        color: bucket.count == 0
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bucket.label,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
