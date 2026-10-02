// Outbox screen: queued and rejected offline check-ins. Failed rows keep
// the server's own rejection message until explicitly dismissed — nothing
// is ever silently dropped.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/local_database.dart';
import 'offline_providers.dart';

/// Banner shown on Today/Ledger whenever the outbox is non-empty.
class OutboxBanner extends ConsumerWidget {
  const OutboxBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OutboxCheckin>> outbox = ref.watch(outboxProvider);
    return outbox.maybeWhen(
      data: (List<OutboxCheckin> rows) {
        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }
        final int failed = rows
            .where((OutboxCheckin r) => r.status == 'failed')
            .length;
        final String text = failed > 0
            ? '$failed check-in${failed == 1 ? '' : 's'} need attention.'
            : '${rows.length} check-in${rows.length == 1 ? '' : 's'} '
                  'queued — syncs automatically.';
        return Card(
          child: ListTile(
            leading: Icon(
              failed > 0
                  ? Icons.warning_amber_outlined
                  : Icons.cloud_upload_outlined,
            ),
            title: Text(text),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/outbox'),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class OutboxScreen extends ConsumerWidget {
  const OutboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OutboxCheckin>> outbox = ref.watch(outboxProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Outbox')),
      body: SafeArea(
        child: outbox.when(
          data: (List<OutboxCheckin> rows) {
            if (rows.isEmpty) {
              return const EmptyView(
                message: 'Nothing queued. Every check-in is on the server.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(syncNowProvider);
                ref.invalidate(outboxProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  const Text(
                    'Check-ins sync oldest-first when you are back online. '
                    'Rejected ones stay here with the server\u2019s reason '
                    'until you dismiss them.',
                  ),
                  const SizedBox(height: 16),
                  for (final OutboxCheckin row in rows) _OutboxRow(row: row),
                ],
              ),
            );
          },
          loading: () => const LoadingView(message: 'Loading outbox…'),
          error: (Object error, StackTrace _) => ErrorView(
            message: 'Could not load the outbox.',
            onRetry: () => ref.invalidate(outboxProvider),
          ),
        ),
      ),
    );
  }
}

class _OutboxRow extends ConsumerWidget {
  const _OutboxRow({required this.row});

  final OutboxCheckin row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool failed = row.status == 'failed';
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
                    row.commitmentTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                StatusChip(
                  label: failed ? 'needs attention' : 'queued',
                  color: failed ? Colors.red : Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('For ${row.day}. Queued ${row.createdAt}.'),
            if (failed && (row.errorMessage ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Server said: ${row.errorMessage}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'This check-in arrived after the grace window, so the '
                'server refused it. It stays here on record — nothing was '
                'silently dropped.',
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(syncRepositoryProvider)
                      .dismissFailed(row.localId);
                  ref.invalidate(outboxProvider);
                },
                child: const Text('Dismiss'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
