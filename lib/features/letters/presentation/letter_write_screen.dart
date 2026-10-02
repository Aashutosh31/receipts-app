// Letter writing screen. The day-1 (milestone 0) letter is required until
// written: in required mode the back button is blocked (PopScope) so the
// screen cannot be skipped.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../contract/domain/contract_models.dart';
import '../../contract/presentation/contract_providers.dart';
import '../data/letter_repository.dart';
import '../domain/letter_models.dart';
import 'letter_providers.dart';

class LetterWriteScreen extends ConsumerStatefulWidget {
  const LetterWriteScreen({
    super.key,
    required this.milestone,
    required this.isRequired,
  });

  final int milestone;
  final bool isRequired;

  @override
  ConsumerState<LetterWriteScreen> createState() => _LetterWriteScreenState();
}

class _LetterWriteScreenState extends ConsumerState<LetterWriteScreen> {
  final TextEditingController _body = TextEditingController();
  bool _saved = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  String _prompt() {
    return switch (widget.milestone) {
      0 =>
        'Write to the you who finishes this. Why did you start? '
            'What should future you remember on the hard days?',
      30 => 'Write to your day-30 self. What do you hope is true by then?',
      60 => 'Write to your day-60 self. What will you have proven?',
      _ => 'Write to your day-90 self. Who did these 90 days make you?',
    };
  }

  Future<void> _save(String contractId) async {
    final String? problem = validateLetterBody(_body.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(letterRepositoryProvider)
          .writeLetter(
            contractId: contractId,
            unlockDayNumber: widget.milestone,
            body: _body.text,
          );
      ref.invalidate(lettersProvider(contractId));
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = true;
        _isLoading = false;
      });
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/letters');
      }
    } on LetterFailure catch (e) {
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
    final AsyncValue<Contract?> active = ref.watch(activeContractProvider);
    return PopScope(
      canPop: !widget.isRequired || _saved,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.milestone == 0
                ? 'Letter to future you'
                : 'Day ${widget.milestone} letter',
          ),
          automaticallyImplyLeading: !widget.isRequired || _saved,
        ),
        body: SafeArea(
          child: active.when(
            data: (Contract? contract) {
              if (contract == null) {
                return const EmptyView(
                  message: 'Sign a contract before writing letters.',
                );
              }
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (widget.isRequired)
                      Text(
                        'Required before day 1 ends. One honest letter — '
                        'future you opens it later.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    const SizedBox(height: 8),
                    Text(_prompt()),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _body,
                        maxLines: null,
                        expands: true,
                        maxLength: 5000,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Dear future me…',
                          border: OutlineInputBorder(),
                        ),
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
                      label: 'Seal it (cannot be edited)',
                      isLoading: _isLoading,
                      onPressed: () => _save(contract.id),
                    ),
                  ],
                ),
              );
            },
            loading: () => const LoadingView(message: 'Loading…'),
            error: (Object error, StackTrace _) => ErrorView(
              message: 'Could not load your contract.',
              onRetry: () => ref.invalidate(activeContractProvider),
            ),
          ),
        ),
      ),
    );
  }
}
