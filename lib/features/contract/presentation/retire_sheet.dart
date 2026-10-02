// Commitment retirement friction sheet. Retiring is permanent and recorded:
// the screen shows the current streak and day number, requires a written
// reason, and writes both the database trigger row and the user's own reason
// row into contract_changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../reminders/presentation/reminder_providers.dart';
import '../data/contract_repository.dart';
import '../domain/contract_models.dart';
import 'contract_providers.dart';

/// Runs the retire flow for one commitment. Returns when done or dismissed.
Future<void> showRetireSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
  required String commitmentId,
  required String commitmentTitle,
  required int streak,
  required int dayNumber,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _RetireView(
      contract: contract,
      commitmentId: commitmentId,
      commitmentTitle: commitmentTitle,
      streak: streak,
      dayNumber: dayNumber,
    ),
  );
  ref.invalidate(commitmentsProvider(contract.id));
  ref.invalidate(ledgerProvider(contract.id));
  ref.invalidate(streakProvider(contract.id));
  ref.invalidate(contractChangesProvider(contract.id));
  ref.invalidate(reminderRefreshProvider);
}

class _RetireView extends ConsumerStatefulWidget {
  const _RetireView({
    required this.contract,
    required this.commitmentId,
    required this.commitmentTitle,
    required this.streak,
    required this.dayNumber,
  });

  final Contract contract;
  final String commitmentId;
  final String commitmentTitle;
  final int streak;
  final int dayNumber;

  @override
  ConsumerState<_RetireView> createState() => _RetireViewState();
}

class _RetireViewState extends ConsumerState<_RetireView> {
  final TextEditingController _reason = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _retire() async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Write the honest reason. It goes on record.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(contractRepositoryProvider)
          .retireCommitment(
            commitmentId: widget.commitmentId,
            contractId: widget.contract.id,
            reason: _reason.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ContractFailure catch (e) {
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Retire “${widget.commitmentTitle}”?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This is permanent. The commitment leaves your daily list, '
                'its history stays on the ledger, and this change is '
                'recorded under your name.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Day ${widget.dayNumber} of 90 · streak ${widget.streak}. '
                    'Retiring now costs you this line of the contract.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Why are you retiring it? (required)',
                  hintText: 'One honest sentence',
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
              const SizedBox(height: 8),
              AppButton(
                label: 'Retire it (recorded)',
                isLoading: _isLoading,
                onPressed: _retire,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
