// Post-auth gate: sends first-time users to onboarding and contract
// holders to Today. Keeps async contract loading out of the router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';

class GateScreen extends ConsumerWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
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
