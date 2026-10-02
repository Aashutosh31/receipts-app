// Final Receipt screen (day 90): promised vs kept, longest streak, top
// excuse, and the day-1 letter. The shareable card below shows aggregates
// only — no letter text, no free-text notes, no names.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/streak_logic.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../../excuse/domain/excuse_models.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/final_receipt.dart';
import '../domain/letter_models.dart';
import 'letter_providers.dart';
import 'receipt_share.dart';

class FinalReceiptScreen extends ConsumerStatefulWidget {
  const FinalReceiptScreen({super.key});

  @override
  ConsumerState<FinalReceiptScreen> createState() => _FinalReceiptScreenState();
}

class _FinalReceiptScreenState extends ConsumerState<FinalReceiptScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share(FinalReceiptStats stats) async {
    setState(() => _isSharing = true);
    final String? problem = await shareReceiptCard(
      context: context,
      boundaryKey: _cardKey,
      shareText: receiptShareText(
        promised: stats.promised,
        kept: stats.kept,
        longestStreak: stats.longestStreak,
      ),
      fileName: 'receipt-90-days.png',
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSharing = false);
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return active.when(
      data: (Contract? contract) {
        if (contract == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(message: 'No contract, no receipt.'),
          );
        }
        return _FinalBody(
          contract: contract,
          cardKey: _cardKey,
          isSharing: _isSharing,
          onShare: _share,
        );
      },
      loading: () => const Scaffold(body: LoadingView(message: 'Loading…')),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Could not load the receipt.',
          onRetry: () => ref.invalidate(activeContractProvider),
        ),
      ),
    );
  }
}

class _FinalBody extends ConsumerWidget {
  const _FinalBody({
    required this.contract,
    required this.cardKey,
    required this.isSharing,
    required this.onShare,
  });

  final Contract contract;
  final GlobalKey cardKey;
  final bool isSharing;
  final Future<void> Function(FinalReceiptStats stats) onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LedgerEntry>> ledger = ref.watch(
      ledgerProvider(contract.id),
    );
    final AsyncValue<List<Excuse>> excuses = ref.watch(excusesProvider);
    final AsyncValue<List<LetterEntry>> letters = ref.watch(
      lettersProvider(contract.id),
    );
    final AsyncValue<StreakInfo> streak = ref.watch(
      streakProvider(contract.id),
    );
    if (letters.isLoading ||
        ledger.isLoading ||
        excuses.isLoading ||
        streak.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Final Receipt')),
        body: const LoadingView(message: 'Tallying 90 days…'),
      );
    }
    final Object? error =
        letters.asError?.error ??
        ledger.asError?.error ??
        excuses.asError?.error ??
        streak.asError?.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Final Receipt')),
        body: ErrorView(
          message: 'Could not tally the receipt.',
          onRetry: () {
            ref.invalidate(lettersProvider(contract.id));
            ref.invalidate(ledgerProvider(contract.id));
            ref.invalidate(excusesProvider);
            ref.invalidate(streakProvider(contract.id));
          },
        ),
      );
    }
    final List<LetterEntry> rows = letters.requireValue;
    final bool unlocked =
        rows
            .where((LetterEntry l) => l.unlockDayNumber == 90)
            .firstOrNull
            ?.isUnlocked ??
        false;
    if (!unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Final Receipt')),
        body: EmptyView(
          message: 'Not yet. The Final Receipt unlocks with day 90.',
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
      letters: rows,
      serverToday: streak.requireValue.today,
      mode: contract.mode == ContractModeDto.hard
          ? ContractMode.hard
          : ContractMode.kind,
    );
    final ThemeData theme = Theme.of(context);
    final int percent = (stats.keptRate * 100).round();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Receipt'),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            RepaintBoundary(
              key: cardKey,
              child: _ReceiptCard(stats: stats),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Promised vs kept: ${stats.kept} of ${stats.promised} '
                      '($percent%).',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Longest streak: ${stats.longestStreak} days.'),
                    const SizedBox(height: 4),
                    Text(
                      stats.topExcuse == null
                          ? 'Top excuse: none filed.'
                          : 'Top excuse: \'${stats.topExcuse}\' '
                                '(${stats.topExcuseCount} times).',
                    ),
                  ],
                ),
              ),
            ),
            if (stats.dayOneLetter?.body != null) ...<Widget>[
              const SizedBox(height: 16),
              Text('Your day-1 letter', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(stats.dayOneLetter!.body!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Share receipt image',
              isLoading: isSharing,
              onPressed: () => onShare(stats),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aggregates-only card captured for sharing. Never add letter text,
/// free-text notes, or names here.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.stats});

  final FinalReceiptStats stats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int percent = (stats.keptRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('RECEIPTS · 90 DAYS', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(
            '$percent%',
            style: theme.textTheme.displayMedium,
            semanticsLabel: '$percent percent kept',
          ),
          Text(
            '${stats.kept} of ${stats.promised} kept',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text('Longest streak: ${stats.longestStreak} days'),
          Text(
            stats.topExcuse == null
                ? 'Top excuse: none'
                : 'Top excuse: ${stats.topExcuse} ×${stats.topExcuseCount}',
          ),
          const SizedBox(height: 12),
          const Text('Consistency, not punishment.'),
        ],
      ),
    );
  }
}
