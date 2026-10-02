// Squad feed screen: per-member display name, day number, today's
// kept/missed status, streak, and missed count. Nudge buttons send the one
// preset daily nudge; already-nudged members show as sent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/squad_repository.dart';
import '../domain/squad_models.dart';
import 'squad_providers.dart';

class SquadFeedScreen extends ConsumerWidget {
  const SquadFeedScreen({super.key, required this.squadId, this.squadName});

  final String squadId;
  final String? squadName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SquadFeedRow>> feed = ref.watch(
      squadFeedProvider(squadId),
    );
    final AsyncValue<Set<String>> nudged = ref.watch(
      nudgedTodayProvider(squadId),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(squadName ?? 'Squad feed'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave squad',
            onPressed: () => _leave(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: feed.when(
          data: (List<SquadFeedRow> rows) {
            final Set<String> sent = nudged.maybeWhen(
              data: (Set<String> v) => v,
              orElse: () => <String>{},
            );
            if (rows.isEmpty) {
              return const EmptyView(message: 'Nobody here yet.');
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(squadFeedProvider(squadId));
                ref.invalidate(nudgedTodayProvider(squadId));
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  const Text(
                    'Misses are visible. Notes, letters, and excuses stay '
                    'private. One preset nudge per member per day.',
                  ),
                  const SizedBox(height: 16),
                  for (final SquadFeedRow row in rows)
                    _FeedRow(
                      row: row,
                      nudged: sent.contains(row.memberUserId),
                      onNudge: () => _nudge(context, ref, row),
                    ),
                ],
              ),
            );
          },
          loading: () => const LoadingView(message: 'Loading feed…'),
          error: (Object error, StackTrace _) => ErrorView(
            message: _readable(error),
            onRetry: () {
              ref.invalidate(squadFeedProvider(squadId));
              ref.invalidate(nudgedTodayProvider(squadId));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _nudge(
    BuildContext context,
    WidgetRef ref,
    SquadFeedRow row,
  ) async {
    try {
      await ref
          .read(squadRepositoryProvider)
          .sendNudge(squadId: squadId, toUserId: row.memberUserId);
      ref.invalidate(nudgedTodayProvider(squadId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Nudged ${row.displayName}.')));
      }
    } on SquadFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await showFinalConfirm(
      context: context,
      title: 'Leave this squad?',
      body:
          'Your misses disappear from their feed. '
          'You can rejoin later with a code.',
      confirmLabel: 'Leave',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(squadRepositoryProvider).leaveSquad(squadId);
      ref.invalidate(mySquadsProvider);
      if (context.mounted) {
        context.go('/squads');
      }
    } on SquadFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({
    required this.row,
    required this.nudged,
    required this.onNudge,
  });

  final SquadFeedRow row;
  final bool nudged;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String status = row.todayStatus ?? 'no contract';
    final Color color = switch (row.todayStatus) {
      'kept' => Colors.green,
      'missed' => Colors.red,
      'paused' => Colors.grey,
      _ => Colors.blueGrey,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                StatusChip(label: status, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              row.hasContract
                  ? 'Day ${row.dayNumber} · streak ${row.currentStreak} · '
                        '${row.missedCount} missed'
                  : 'No active contract.',
              semanticsLabel: row.hasContract
                  ? '${row.displayName}, day ${row.dayNumber}, '
                        'streak ${row.currentStreak}, ${row.missedCount} missed'
                  : '${row.displayName} has no active contract',
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: row.hasContract && !nudged ? onNudge : null,
              child: Text(nudged ? 'Nudged today' : 'Nudge'),
            ),
          ],
        ),
      ),
    );
  }
}

String _readable(Object error) {
  if (error is SquadFailure) {
    return error.message;
  }
  return 'Something went wrong loading the feed.';
}
