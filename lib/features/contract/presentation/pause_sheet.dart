// Sick/Injury pause sheet: declare a new pause starting today, or end the
// currently open one. Pauses are recorded visibly and never break streaks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/contract_repository.dart';
import '../domain/contract_models.dart';
import 'contract_providers.dart';

/// Shows declare-or-end pause UI. Returns when done or dismissed.
Future<void> showPauseSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Contract contract,
  required Pause? openPause,
  required DateTime serverToday,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      if (openPause != null) {
        return _EndPauseView(
          contract: contract,
          openPause: openPause,
          serverToday: serverToday,
        );
      }
      return _DeclarePauseView(contract: contract, serverToday: serverToday);
    },
  );
  // Refresh pause-dependent state whatever happened in the sheet.
  ref.invalidate(pausesProvider(contract.id));
}

class _DeclarePauseView extends ConsumerStatefulWidget {
  const _DeclarePauseView({required this.contract, required this.serverToday});

  final Contract contract;
  final DateTime serverToday;

  @override
  ConsumerState<_DeclarePauseView> createState() => _DeclarePauseViewState();
}

class _DeclarePauseViewState extends ConsumerState<_DeclarePauseView> {
  String _type = 'sick';
  bool _isLoading = false;
  String? _error;

  Future<void> _declare() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(contractRepositoryProvider)
          .declarePause(
            contractId: widget.contract.id,
            type: _type,
            startDay: widget.serverToday,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Declare a pause', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Sick or injured? Declare it. The pause is recorded visibly in '
              'your ledger and does not break your streak. Pausing does not '
              'erase days before today.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment(value: 'sick', label: Text('Sick')),
                ButtonSegment(value: 'injury', label: Text('Injury')),
              ],
              selected: <String>{_type},
              onSelectionChanged: (Set<String> selected) =>
                  setState(() => _type = selected.first),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Declare pause from today',
              isLoading: _isLoading,
              onPressed: _declare,
            ),
          ],
        ),
      ),
    );
  }
}

class _EndPauseView extends ConsumerStatefulWidget {
  const _EndPauseView({
    required this.contract,
    required this.openPause,
    required this.serverToday,
  });

  final Contract contract;
  final Pause openPause;
  final DateTime serverToday;

  @override
  ConsumerState<_EndPauseView> createState() => _EndPauseViewState();
}

class _EndPauseViewState extends ConsumerState<_EndPauseView> {
  bool _isLoading = false;
  String? _error;

  Future<void> _end() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(contractRepositoryProvider)
          .endPause(pauseId: widget.openPause.id, endDay: widget.serverToday);
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('End your pause?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.openPause.type} pause stays on the record. '
              'Ending it resumes normal scoring from today.',
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'End pause',
              isLoading: _isLoading,
              onPressed: _end,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep pausing'),
            ),
          ],
        ),
      ),
    );
  }
}
