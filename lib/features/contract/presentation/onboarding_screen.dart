// "Sign the Contract" onboarding: 3-5 commitments, Hard/Kind mode with
// plain-language explanations, and a pledge screen signed by typing a name.
// Writes via the atomic create_contract_with_commitments RPC.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/contract_repository.dart';
import '../domain/contract_draft.dart';
import '../domain/contract_models.dart';
import 'contract_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final ContractDraft _draft = ContractDraft();
  final TextEditingController _signature = TextEditingController();
  final List<TextEditingController> _titles = <TextEditingController>[];
  final List<TextEditingController> _times = <TextEditingController>[];
  int _step = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void dispose() {
    _signature.dispose();
    for (final TextEditingController c in [..._titles, ..._times]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    while (_titles.length < _draft.commitments.length) {
      _titles.add(TextEditingController());
      _times.add(TextEditingController());
    }
  }

  void _pushToDraft() {
    for (int i = 0; i < _draft.commitments.length; i++) {
      _draft.commitments[i].title = _titles[i].text;
      _draft.commitments[i].targetTime = _times[i].text;
    }
    _draft.signature = _signature.text;
  }

  Future<void> _sign() async {
    _pushToDraft();
    final String? problem = _draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final DateTime now = DateTime.now();
      await ref
          .read(contractRepositoryProvider)
          .createContract(
            startDate: DateTime.utc(now.year, now.month, now.day),
            mode: _draft.mode!,
            commitments: _draft.commitments,
          );
      ref.invalidate(activeContractProvider);
      if (mounted) {
        context.go('/today');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sign the Contract')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Step ${_step + 1} of 3',
                style: theme.textTheme.labelLarge,
                semanticsLabel: 'Step ${_step + 1} of 3',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_step) {
                  0 => _CommitmentsStep(
                    titles: _titles,
                    times: _times,
                    canAddMore: _draft.canAddMore,
                    canRemove: _draft.canRemove,
                    onAdd: () {
                      setState(() {
                        _draft.commitments.add(CommitmentDraft());
                        _syncControllers();
                      });
                    },
                    onRemove: () {
                      setState(() {
                        _draft.commitments.removeLast();
                        _titles.removeLast().dispose();
                        _times.removeLast().dispose();
                      });
                    },
                  ),
                  1 => _ModeStep(
                    mode: _draft.mode,
                    onPick: (ContractModeDto mode) =>
                        setState(() => _draft.mode = mode),
                  ),
                  _ => _PledgeStep(draft: _draft, signature: _signature),
                },
              ),
              if (_error != null) ...<Widget>[
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  semanticsLabel: 'Error: $_error',
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: <Widget>[
                  if (_step > 0)
                    TextButton(
                      onPressed: () {
                        _pushToDraft();
                        setState(() {
                          _step -= 1;
                          _error = null;
                        });
                      },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _pushToDraft();
                            if (_step < 2) {
                              setState(() {
                                _step += 1;
                                _error = null;
                              });
                            } else {
                              _sign();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step < 2 ? 'Continue' : 'Sign it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitmentsStep extends StatelessWidget {
  const _CommitmentsStep({
    required this.titles,
    required this.times,
    required this.canAddMore,
    required this.canRemove,
    required this.onAdd,
    required this.onRemove,
  });

  final List<TextEditingController> titles;
  final List<TextEditingController> times;
  final bool canAddMore;
  final bool canRemove;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      children: <Widget>[
        Text(
          'Pick 3 to 5 non-negotiable daily commitments. These lock for '
          '90 days — changing one later is costly and recorded.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < titles.length; i++) ...<Widget>[
          TextField(
            controller: titles[i],
            maxLength: 120,
            decoration: InputDecoration(
              labelText: 'Commitment ${i + 1}',
              hintText: 'e.g. Run 20 minutes',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: times[i],
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Target time (optional)',
              hintText: 'e.g. 06:30',
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: <Widget>[
            if (canAddMore)
              OutlinedButton(onPressed: onAdd, child: const Text('+ Add')),
            if (canAddMore && canRemove) const SizedBox(width: 8),
            if (canRemove)
              TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      ],
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({required this.mode, required this.onPick});

  final ContractModeDto? mode;
  final ValueChanged<ContractModeDto> onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      children: <Widget>[
        Text(
          'Choose how misses treat your streak.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          selected: mode == ContractModeDto.hard,
          title: 'Hard Mode',
          body:
              'Any missed day resets your streak to zero. No excuses, '
              'no carry-over. Pick this if you want the harshest mirror.',
          onTap: () => onPick(ContractModeDto.hard),
        ),
        const SizedBox(height: 12),
        _ModeCard(
          selected: mode == ContractModeDto.kind,
          title: 'Kind Mode',
          body:
              'Up to 2 missed days per contract are forgiven without '
              'resetting your streak. The third miss resets it. Pick this if '
              'you want firm but human.',
          onTap: () => onPick(ContractModeDto.kind),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PledgeStep extends StatelessWidget {
  const _PledgeStep({required this.draft, required this.signature});

  final ContractDraft draft;
  final TextEditingController signature;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String end = DateFormat.yMMMMd().format(
      draft.endDate(DateTime.now()),
    );
    return ListView(
      children: <Widget>[
        Text('Read this. Then sign it.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'For the next 90 days, ending $end, I keep the commitments '
              'above — every day, no edits, no backfills. A miss is a miss '
              'and it stays on the ledger. If I fall, I tag the excuse '
              'honestly and keep going.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: signature,
          decoration: const InputDecoration(
            labelText: 'Type your name to sign',
            hintText: 'Your signature',
          ),
        ),
      ],
    );
  }
}
