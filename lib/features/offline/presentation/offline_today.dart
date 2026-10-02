// Offline Today body: renders purely from the local cache with an honest
// offline label. Done taps enqueue check-ins (device date, server judges)
// and optimistically mark the cached row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/domain/contract_models.dart';
import '../../ledger/domain/ledger_models.dart';
import '../data/local_cache.dart';
import 'offline_providers.dart';
import 'outbox_screen.dart';

class OfflineTodayBody extends ConsumerWidget {
  const OfflineTodayBody({super.key, required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CachedTodayView?> view = ref.watch(
      cachedTodayProvider(contract.id),
    );
    return view.when(
      data: (CachedTodayView? cached) {
        if (cached == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Today')),
            body: const EmptyView(
              message:
                  'Offline with no cached data yet. '
                  'Open the app online once to cache your contract.',
            ),
            bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
          );
        }
        return _OfflineTodayLoaded(contract: contract, cached: cached);
      },
      loading: () =>
          const Scaffold(body: LoadingView(message: 'Loading cached today…')),
      error: (Object error, StackTrace _) => Scaffold(
        body: ErrorView(
          message: 'Could not load cached data.',
          onRetry: () => ref.invalidate(cachedTodayProvider(contract.id)),
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
      ),
    );
  }
}

class _OfflineTodayLoaded extends ConsumerWidget {
  const _OfflineTodayLoaded({required this.contract, required this.cached});

  final Contract contract;
  final CachedTodayView cached;

  Future<void> _enqueue(
    BuildContext context,
    WidgetRef ref,
    CachedTodayRow row,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime.utc(now.year, now.month, now.day);
    final bool confirmed = await showFinalConfirm(
      context: context,
      title: 'Queue it?',
      body:
          '“${row.title}” will be queued as done for '
          '${formatServerDay(day)}. It syncs when you are back online — '
          'the server judges the date, and a late arrival is rejected, '
          'never silently dropped.',
      confirmLabel: 'Queue done',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final String? userId = ref
        .read(currentUserIdProvider)
        .maybeWhen(data: (String? id) => id, orElse: () => null);
    if (userId == null || !context.mounted) {
      return;
    }
    final LocalCache cache = ref.read(localCacheProvider);
    await cache.enqueueCheckIn(
      userId: userId,
      contractId: contract.id,
      commitmentId: row.commitmentId,
      commitmentTitle: row.title,
      day: day,
    );
    await cache.writeLocalDone(
      userId: userId,
      contractId: contract.id,
      commitmentId: row.commitmentId,
      title: row.title,
      day: day,
    );
    ref.invalidate(cachedTodayProvider(contract.id));
    ref.invalidate(outboxProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queued — will sync when you are back online.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Offline — showing cached data. Numbers below are '
                  'approximate until the next sync.',
                ),
              ),
            ),
            if (cached.asOf != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Cached ${cached.asOf!.split('T').first}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            const OutboxBanner(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${cached.streak}',
                      style: theme.textTheme.displayMedium,
                      semanticsLabel:
                          'Cached streak ${cached.streak} days (approximate)',
                    ),
                    Text(
                      'day streak · offline',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${todayStatusLine(dayNumber: cached.dayNumber, doneCount: cached.doneCount, totalCount: cached.totalCount, streak: cached.streak, isPaused: cached.isPaused)} (offline, approximate)',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            if (cached.isPaused) ...<Widget>[
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Paused today — no check-in needed.'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (cached.rows.isEmpty)
              const EmptyView(message: 'Nothing cached for today.')
            else
              for (final CachedTodayRow row in cached.rows)
                Card(
                  child: ListTile(
                    title: Text(row.title),
                    subtitle: Text(
                      row.done
                          ? row.queued
                                ? 'Queued — will sync.'
                                : 'Done. On the record.'
                          : 'Not yet logged today.',
                    ),
                    trailing: row.done
                        ? Icon(
                            row.queued
                                ? Icons.cloud_upload_outlined
                                : Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : FilledButton.tonal(
                            onPressed: cached.isPaused
                                ? null
                                : () => _enqueue(context, ref, row),
                            child: const Text('Done'),
                          ),
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 0),
    );
  }
}
