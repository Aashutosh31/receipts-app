// Notification permission flow. Explanation first, system prompts second.
// Honest about fallbacks: without exact alarms reminders still arrive, just
// at approximate times; on iOS there are no true alarms at all.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import 'reminder_providers.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

enum _Stage { explaining, notificationsDenied, exactChoice }

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  _Stage _stage = _Stage.explaining;
  bool _isLoading = false;

  Future<void> _markAsked() async {
    final store = await ref.read(settingsStoreProvider.future);
    final current = await ref.read(reminderSettingsProvider.future);
    await store.save(current.copyWith(permissionAsked: true));
    ref.invalidate(reminderSettingsProvider);
  }

  Future<void> _done() async {
    await _markAsked();
    ref.invalidate(reminderRefreshProvider);
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/today');
      }
    }
  }

  Future<void> _enable() async {
    setState(() => _isLoading = true);
    final service = ref.read(notificationServiceProvider);
    final bool granted = await service.requestNotificationsPermission();
    if (!mounted) {
      return;
    }
    if (!granted) {
      setState(() {
        _isLoading = false;
        _stage = _Stage.notificationsDenied;
      });
      return;
    }
    final bool exact = await service.canScheduleExact();
    if (!mounted) {
      return;
    }
    if (exact) {
      setState(() => _isLoading = false);
      await _done();
      return;
    }
    setState(() {
      _isLoading = false;
      _stage = _Stage.exactChoice;
    });
  }

  Future<void> _requestExact() async {
    final service = ref.read(notificationServiceProvider);
    await service.requestExactAlarms();
    if (!mounted) {
      return;
    }
    if (await service.canScheduleExact()) {
      await _done();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            if (_stage == _Stage.explaining) ...<Widget>[
              Text(
                'Reminders keep the contract honest.',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Receipts can nudge you at each commitment\u2019s target time, '
                'check back 30 minutes later if nothing is logged, and give '
                'one last call in the evening.\n\n'
                'Two things to know first:\n'
                '• Notifications permission lets the app show these nudges.\n'
                '• Exact timing needs the Alarms permission. If you deny it, '
                'reminders still arrive — just at approximate times. '
                'We will tell you which one you have.\n'
                '• On iPhone there are no true alarms, only notifications, '
                'and the system keeps at most 64 scheduled ones.',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Enable reminders',
                isLoading: _isLoading,
                onPressed: _enable,
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _done, child: const Text('Skip for now')),
            ],
            if (_stage == _Stage.notificationsDenied) ...<Widget>[
              Text(
                'Notifications are off.',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Without notification permission there are no reminders at '
                'all. To turn them on later: open system Settings → Apps → '
                'Receipts → Notifications, then come back and tap below.',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Check again',
                isLoading: _isLoading,
                onPressed: _enable,
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _done, child: const Text('Continue muted')),
            ],
            if (_stage == _Stage.exactChoice) ...<Widget>[
              Text(
                'Approximate timing only.',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Exact alarms were not granted, so reminders may arrive a '
                'few minutes late. That is fine — they still arrive. You can '
                'allow exact timing in system Settings → Apps → Receipts → '
                'Alarms & reminders.',
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Allow exact timing',
                isLoading: _isLoading,
                onPressed: _requestExact,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _done,
                child: const Text('Continue with approximate times'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
