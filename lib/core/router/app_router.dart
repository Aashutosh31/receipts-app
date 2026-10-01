import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Stage 1 foundation router. Feature routes (contract, ledger, letters,
/// squads) land in later stages. This keeps navigation centralized so UI
/// never touches Supabase directly (AGENTS.md architecture).
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const Scaffold(body: SafeArea(child: _FoundationHome()));
      },
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Text(
          'Route not found: ${state.matchedLocation}',
          semanticsLabel: 'Route not found',
        ),
      ),
    );
  },
);

class _FoundationHome extends StatelessWidget {
  const _FoundationHome();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Receipts',
          style: theme.textTheme.displaySmall,
          semanticsLabel: 'Receipts home',
        ),
        const SizedBox(height: 8),
        Text(
          'Stage 1: foundation ready. Connect Supabase to start your contract.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text('Consistency, not punishment.', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
