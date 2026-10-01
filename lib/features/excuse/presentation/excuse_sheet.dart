// Required "Tag your excuse" flow. Presented on app open while unexcused
// misses inside the 48-hour window exist. Non-dismissible: each miss must
// be tagged (reason + optional note) before the sheet closes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../data/excuse_repository.dart';
import '../domain/excuse_models.dart';

/// Steps through every [pending] miss. Returns when all are tagged.
Future<void> showPendingExcuses({
  required BuildContext context,
  required WidgetRef ref,
  required String contractId,
  required List<PendingExcuse> pending,
}) async {
  if (pending.isEmpty) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        _ExcuseFlow(contractId: contractId, pending: pending),
  );
  ref.invalidate(excusesProvider);
}

class _ExcuseFlow extends ConsumerStatefulWidget {
  const _ExcuseFlow({required this.contractId, required this.pending});

  final String contractId;
  final List<PendingExcuse> pending;

  @override
  ConsumerState<_ExcuseFlow> createState() => _ExcuseFlowState();
}

class _ExcuseFlowState extends ConsumerState<_ExcuseFlow> {
  int _index = 0;
  ExcuseReason? _reason;
  final TextEditingController _note = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _error = 'Pick the honest reason.');
      return;
    }
    final PendingExcuse current = widget.pending[_index];
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(excuseRepositoryProvider)
          .fileExcuse(
            commitmentId: current.commitmentId,
            day: current.day,
            reason: _reason!,
            freeText: _note.text,
          );
      if (!mounted) {
        return;
      }
      if (_index + 1 >= widget.pending.length) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _index += 1;
          _reason = null;
          _note.clear();
          _isLoading = false;
        });
      }
    } on ExcuseFailure catch (e) {
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
    final PendingExcuse current = widget.pending[_index];
    final String day = DateFormat.yMMMMd().format(current.day);
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
                'Tag your excuse (${_index + 1} of ${widget.pending.length})',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '“${current.commitmentTitle}” on $day was missed. '
                'Name it honestly — then it is on the record and you move on.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExcuseReason.values.map((ExcuseReason reason) {
                  final bool selected = _reason == reason;
                  return ChoiceChip(
                    label: Text(reason.name),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _reason = reason;
                      _error = null;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                maxLength: 280,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'One honest sentence',
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
              const SizedBox(height: 16),
              AppButton(
                label: 'Tag it',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
