// Reminder settings: quiet hours, per-commitment toggles, tone cap,
// live notification status, and sign out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../offline/presentation/offline_providers.dart';
import '../data/settings_store.dart';
import '../domain/message_engine.dart';
import 'reminder_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReminderSettings> settings = ref.watch(
      reminderSettingsProvider,
    );
    final AsyncValue<ReminderStatus> status = ref.watch(reminderStatusProvider);
    final AsyncValue<Contract?> contract = ref.watch(activeContractProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        data: (ReminderSettings current) {
          final String? contractId = contract.maybeWhen(
            data: (Contract? c) => c?.id,
            orElse: () => null,
          );
          return _SettingsBody(
            settings: current,
            status: status.maybeWhen(
              data: (ReminderStatus s) => s,
              orElse: () => null,
            ),
            contractId: contractId,
          );
        },
        loading: () => const LoadingView(message: 'Loading settings…'),
        error: (Object error, StackTrace _) => ErrorView(
          message: 'Could not load settings.',
          onRetry: () => ref.invalidate(reminderSettingsProvider),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({
    required this.settings,
    required this.status,
    required this.contractId,
  });

  final ReminderSettings settings;
  final ReminderStatus? status;
  final String? contractId;

  Future<void> _save(WidgetRef ref, ReminderSettings next) async {
    final ReminderSettingsStore store = await ref.read(
      settingsStoreProvider.future,
    );
    await store.save(next);
    ref.invalidate(reminderSettingsProvider);
    ref.invalidate(reminderRefreshProvider);
  }

  String _clock(int minutes) {
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final int initial = isStart
        ? settings.quietStartMinutes
        : settings.quietEndMinutes;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    final int minutes = picked.hour * 60 + picked.minute;
    await _save(
      ref,
      settings.copyWith(
        quietStartMinutes: isStart ? minutes : null,
        quietEndMinutes: isStart ? null : minutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Commitment>> commitments = contractId == null
        ? const AsyncValue.data(<Commitment>[])
        : ref.watch(commitmentsProvider(contractId!));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Notifications', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  status == null
                      ? 'Checking status…'
                      : status!.enabled
                      ? 'On${status!.exact ? ' · exact timing' : ' · approximate timing'}'
                            ' · ${status!.pending} scheduled'
                      : 'Off — no reminders will arrive',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/notifications/intro'),
                  child: const Text('Review notification setup'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Quiet hours', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                title: const Text('Start'),
                trailing: Text(_clock(settings.quietStartMinutes)),
                onTap: () => _pickTime(context, ref, isStart: true),
              ),
              ListTile(
                title: const Text('End'),
                trailing: Text(_clock(settings.quietEndMinutes)),
                onTap: () => _pickTime(context, ref, isStart: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Reminders inside quiet hours move to the end of the window.',
        ),
        const SizedBox(height: 24),
        Text('Tone', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ReminderTone>(
          segments: const <ButtonSegment<ReminderTone>>[
            ButtonSegment(value: ReminderTone.calm, label: Text('Calm')),
            ButtonSegment(value: ReminderTone.firm, label: Text('Firm')),
            ButtonSegment(value: ReminderTone.blunt, label: Text('Blunt')),
          ],
          selected: <ReminderTone>{settings.tone},
          onSelectionChanged: (Set<ReminderTone> selected) =>
              _save(ref, settings.copyWith(tone: selected.first)),
        ),
        const SizedBox(height: 8),
        Text(switch (settings.tone) {
          ReminderTone.calm => 'Gentle nudges only, even after misses.',
          ReminderTone.firm => 'Sharpens after one miss. Never cruel.',
          ReminderTone.blunt =>
            'Full escalation after repeated misses. Still never personal.',
        }),
        const SizedBox(height: 24),
        Text('Per-commitment reminders', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        commitments.maybeWhen(
          // Display-layer filter only: retired commitments stay available
          // in the underlying provider for history and scheduling date
          // math, but get no reminder toggle.
          data: (List<Commitment> items) => Column(
            children: <Widget>[
              for (final Commitment c in items.where((c) => !c.isRetired))
                SwitchListTile(
                  title: Text(c.title),
                  value: settings.enabledFor(c.id),
                  onChanged: (bool value) {
                    final Set<String> disabled = Set<String>.from(
                      settings.disabledCommitmentIds,
                    );
                    if (value) {
                      disabled.remove(c.id);
                    } else {
                      disabled.add(c.id);
                    }
                    _save(
                      ref,
                      settings.copyWith(disabledCommitmentIds: disabled),
                    );
                  },
                ),
            ],
          ),
          orElse: () => const Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 24),
        const SignOutRow(),
        const SizedBox(height: 24),
        Text('Danger zone', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const DeleteAccountRow(),
      ],
    );
  }
}

/// Sign-out row used on the Settings screen.
class SignOutRow extends ConsumerWidget {
  const SignOutRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Sign out'),
      onTap: () async {
        final bool confirmed = await showFinalConfirm(
          context: context,
          title: 'Sign out?',
          body:
              'Your ledger stays safe on the server. '
              'Signing out only ends this session.',
          confirmLabel: 'Sign out',
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        try {
          await ref.read(authRepositoryProvider).signOut();
        } on AuthFailure catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
      },
    );
  }
}

/// Confirms typed DELETE text. Pure for testability.
bool isDeleteConfirmed(String value) => value.trim() == 'DELETE';

/// Danger-zone row: deletes the account server-side (Edge Function, service
/// role stays on the server), wipes local cache + settings, then signs out.
class DeleteAccountRow extends ConsumerStatefulWidget {
  const DeleteAccountRow({super.key});

  @override
  ConsumerState<DeleteAccountRow> createState() => _DeleteAccountRowState();
}

class _DeleteAccountRowState extends ConsumerState<DeleteAccountRow> {
  final TextEditingController _confirm = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!isDeleteConfirmed(_confirm.text)) {
      setState(() => _error = 'Type DELETE to confirm.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      final String? userId = ref
          .read(currentUserIdProvider)
          .maybeWhen(data: (String? id) => id, orElse: () => null);
      if (userId != null) {
        await ref.read(localCacheProvider).clearUser(userId);
        final ReminderSettingsStore store = await ref.read(
          settingsStoreProvider.future,
        );
        await store.delete();
      }
      await ref.read(authRepositoryProvider).signOut();
      // The auth guard routes to sign-in from here.
    } on AuthFailure catch (e) {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Delete my account and data. This erases your contract, '
              'ledger, excuses, pauses, letters, and squad memberships '
              'forever. Squads you created disappear for their members too. '
              'There is no undo.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 12),
            AppButton(
              label: 'Delete everything',
              isLoading: _isLoading,
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
