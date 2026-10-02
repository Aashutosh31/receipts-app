// Post-auth gate: sends first-time users to onboarding and contract
// holders to Today. Keeps async contract loading out of the router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../offline/presentation/offline_providers.dart';
import '../../reminders/presentation/reminder_providers.dart';

class GateScreen extends ConsumerWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    // Sync the outbox + refresh the offline cache on every app open.
    // Best-effort: the gate UI below never depends on it.
    ref.watch(syncNowProvider);
    // Refresh the 7-day reminder window on every app open. Best-effort:
    // the gate UI below never depends on it.
    ref.watch(reminderRefreshProvider);
    // Reconnect: sync again when connectivity returns.
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          context.go(contract == null ? '/contract/new' : '/today');
        });
        return const Scaffold(body: LoadingView(message: 'Opening…'));
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Opening…')),
      error: (Object error, StackTrace _) => Scaffold(
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}
