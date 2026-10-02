// Letter reveal screen: the unlocked body plus the reader's actual stats
// since day 1 (kept rate, top excuse, streak). Locked or missing letters
// show a respectful placeholder instead of the body.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/streak_logic.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/final_receipt.dart';
import '../domain/letter_models.dart';
import 'letter_providers.dart';

class LetterRevealScreen extends ConsumerWidget {
  const LetterRevealScreen({super.key, required this.milestone});

  final int milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(message: 'No contract, no letters.'),
          );
        }
        return _RevealBody(contract: contract, milestone: milestone);
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Loading…')),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Could not load letters.',
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}

class _RevealBody extends ConsumerWidget {
  const _RevealBody({required this.contract, required this.milestone});

  final Contract contract;
  final int milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LetterEntry>> letters = ref.watch(
      lettersProvider(contract.id),
    );
    final AsyncValue<List<LedgerEntry>> ledger = ref.watch(
      ledgerProvider(contract.id),
    );
    final AsyncValue<List<Excuse>> excuses = ref.watch(excusesProvider);
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(contract.id),
    );
    if (letters.isLoading ||
        ledger.isLoading ||
        excuses.isLoading ||
        streak.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(milestoneLabel(milestone))),
        body: const LoadingView(message: 'Opening the envelope…'),
      );
    }
    final Object? error =
        letters.asError?.error ??
        ledger.asError?.error ??
        excuses.asError?.error ??
        streak.asError?.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(milestoneLabel(milestone))),
        body: ErrorView(
          message: 'Could not open this letter.',
          onRetry: () {
            ref.invalidate(lettersProvider(contract.id));
            ref.invalidate(ledgerProvider(contract.id));
            ref.invalidate(excusesProvider);
            ref.invalidate(streakProvider(contract.id));
          },
        ),
      );
    }
    LetterEntry? letter;
    for (final LetterEntry entry in letters.requireValue) {
      if (entry.unlockDayNumber == milestone) {
        letter = entry;
      }
    }
    if (letter == null || !letter.isUnlocked || letter.body == null) {
      return Scaffold(
        appBar: AppBar(title: Text(milestoneLabel(milestone))),
        body: EmptyView(
          message: 'Still sealed. Come back when the server says so.',
          action: FilledButton(
            onPressed: () => context.go('/letters'),
            child: const Text('Back to letters'),
          ),
        ),
      );
    }
    final FinalReceiptStats stats = computeFinalReceipt(
      ledger: ledger.requireValue,
      excuses: excuses.requireValue,
      letters: letters.requireValue,
      serverToday: streak.requireValue.today,
      mode: contract.mode == ContractModeDto.hard
          ? ContractMode.hard
          : ContractMode.kind,
    );
    final ThemeData theme = Theme.of(context);
    final int percent = (stats.keptRate * 100).round();
    return Scaffold(
      appBar: AppBar(title: Text(milestoneLabel(milestone))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  letter.body!,
                  style: theme.textTheme.bodyLarge,
                  semanticsLabel: 'Your letter: ${letter.body!}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Since you wrote it', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${stats.kept} of ${stats.promised} kept ($percent%).',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.topExcuse == null
                          ? 'No excuses filed. Clean.'
                          : 'Top excuse: \'${stats.topExcuse}\' '
                                '(${stats.topExcuseCount} times).',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current streak: ${streak.requireValue.currentStreak} days.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
