// Squads screen: list my squads, create one, join with an invite code.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../data/squad_repository.dart';
import '../domain/squad_models.dart';
import 'squad_providers.dart';

class SquadsScreen extends ConsumerWidget {
  const SquadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Squad>> squads = ref.watch(mySquadsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squads'),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: squads.when(
          data: (List<Squad> rows) {
            if (rows.isEmpty) {
              return EmptyView(
                message:
                    'No squad yet. Start one or join with a code — '
                    '3 to 5 friends who see your misses.',
                action: _CreateJoinButtons(),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mySquadsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  const _CreateJoinButtons(),
                  const SizedBox(height: 16),
                  for (final Squad squad in rows)
                    Card(
                      child: ListTile(
                        title: Text(squad.name),
                        subtitle: const Text('Tap to see the feed.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/squads/${squad.id}?name=${Uri.encodeComponent(squad.name)}',
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const LoadingView(message: 'Loading squads…'),
          error: (Object error, StackTrace _) => ErrorView(
            message: _readable(error),
            onRetry: () => ref.invalidate(mySquadsProvider),
          ),
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 4),
    );
  }
}

class _CreateJoinButtons extends StatelessWidget {
  const _CreateJoinButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext context) => const _CreateSquadDialog(),
            ),
            child: const Text('Create squad'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext context) => const _JoinSquadDialog(),
            ),
            child: const Text('Join with code'),
          ),
        ),
      ],
    );
  }
}

class _CreateSquadDialog extends ConsumerStatefulWidget {
  const _CreateSquadDialog();

  @override
  ConsumerState<_CreateSquadDialog> createState() => _CreateSquadDialogState();
}

class _CreateSquadDialogState extends ConsumerState<_CreateSquadDialog> {
  final TextEditingController _name = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _inviteCode;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ({String id, String inviteCode}) result = await ref
          .read(squadRepositoryProvider)
          .createSquad(_name.text);
      ref.invalidate(mySquadsProvider);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _inviteCode = result.inviteCode;
        });
      }
    } on SquadFailure catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Create squad'),
      content: _inviteCode == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Pick a name. You will get an invite code — '
                  'the squad fits 5 members total, you included.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Squad name',
                    counterText: '',
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Share this code with your friends:'),
                const SizedBox(height: 12),
                SelectableText(
                  _inviteCode!,
                  style: theme.textTheme.displaySmall,
                  semanticsLabel:
                      'Invite code ${_inviteCode!.split('').join(' ')}',
                ),
              ],
            ),
      actions: <Widget>[
        if (_inviteCode == null)
          TextButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_inviteCode == null ? 'Cancel' : 'Done'),
        ),
      ],
    );
  }
}

class _JoinSquadDialog extends ConsumerStatefulWidget {
  const _JoinSquadDialog();

  @override
  ConsumerState<_JoinSquadDialog> createState() => _JoinSquadDialogState();
}

class _JoinSquadDialogState extends ConsumerState<_JoinSquadDialog> {
  final TextEditingController _code = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(squadRepositoryProvider).joinSquad(_code.text);
      ref.invalidate(mySquadsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on SquadFailure catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Join with code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Enter the 6-character invite code.'),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              counterText: '',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : _join,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _readable(Object error) {
  if (error is SquadFailure) {
    return error.message;
  }
  return 'Something went wrong loading squads.';
}
