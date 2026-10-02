// Letters screen: milestone cards with server-time countdowns, reveal
// navigation, and the Final Receipt entry once day 90 unlocks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/letter_models.dart';
import 'letter_providers.dart';

class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            body: EmptyView(
              message: 'No contract yet. Letters need a day 1 first.',
              action: FilledButton(
                onPressed: () => context.go('/contract/new'),
                child: const Text('Sign the Contract'),
              ),
            ),
            bottomNavigationBar: const ReceiptsNavBar(currentIndex: 3),
          );
        }
        return _LettersBody(contract: contract);
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Loading…')),
      error: (Object error, StackTrace _) => Scaffold(
        body: ErrorView(
          message: 'Something went wrong loading letters.',
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}

class _LettersBody extends ConsumerWidget {
  const _LettersBody({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LetterEntry>> letters = ref.watch(
      lettersProvider(contract.id),
    );
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(contract.id),
    );
    if (letters.isLoading || streak.isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading letters…'));
    }
    final Object? error = letters.asError?.error ?? streak.asError?.error;
    if (error != null) {
      return Scaffold(
        body: ErrorView(
          message: 'Could not load letters.',
          onRetry: () {
            ref.invalidate(lettersProvider(contract.id));
            ref.invalidate(streakProvider(contract.id));
          },
        ),
        bottomNavigationBar: const ReceiptsNavBar(currentIndex: 3),
      );
    }
    final List<LetterEntry> rows = letters.requireValue;
    final DateTime serverToday = streak.requireValue.today;
    final Map<int, LetterEntry> byMilestone = <int, LetterEntry>{
      for (final LetterEntry letter in rows) letter.unlockDayNumber: letter,
    };
    final bool finalUnlocked = byMilestone[90]?.isUnlocked ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters'),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lettersProvider(contract.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text(
                'Written on day 1. Opened only when the server says so.',
              ),
              const SizedBox(height: 16),
              for (final int milestone in letterMilestones)
                _MilestoneCard(
                  milestone: milestone,
                  letter: byMilestone[milestone],
                  serverToday: serverToday,
                ),
              if (finalUnlocked) ...<Widget>[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/letters/final'),
                  child: const Text('Open your Final Receipt'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ReceiptsNavBar(currentIndex: 3),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.letter,
    required this.serverToday,
  });

  final int milestone;
  final LetterEntry? letter;
  final DateTime serverToday;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = milestoneLabel(milestone);
    final LetterEntry? row = letter;
    late final String subtitle;
    late final String actionLabel;
    late final VoidCallback? onTap;
    if (row == null) {
      subtitle = milestone == 0
          ? 'Not written yet. Day 1 needs its letter.'
          : 'Not written yet. Write it before day $milestone.';
      actionLabel = 'Write it';
      onTap = () => context.push('/letters/write?milestone=$milestone');
    } else if (row.isUnlocked) {
      subtitle = 'Unlocked. Your past self kept its promise.';
      actionLabel = 'Read it';
      onTap = () => context.push('/letters/reveal/$milestone');
    } else {
      final int left = countdownDays(row.unlockDate, serverToday);
      subtitle = 'Locked. Unlocks in $left day${left == 1 ? '' : 's'}.';
      actionLabel = '';
      onTap = null;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  row != null && row.isUnlocked
                      ? Icons.mail_outline
                      : Icons.lock_outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, semanticsLabel: '$title. $subtitle'),
            if (onTap != null) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
