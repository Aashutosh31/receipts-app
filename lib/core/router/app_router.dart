// Centralized routing with auth guards. The redirect handles only
// authentication (synchronous session check); contract onboarding gating
// lives in [GateScreen], which can load async state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/contract/presentation/onboarding_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/ledger/presentation/app_shell.dart';
import '../../features/ledger/presentation/ledger_screen.dart';
import '../../features/ledger/presentation/today_screen.dart';
import '../../features/letters/domain/letter_models.dart';
import '../../features/letters/presentation/final_receipt_screen.dart';
import '../../features/letters/presentation/letter_reveal_screen.dart';
import '../../features/letters/presentation/letter_write_screen.dart';
import '../../features/letters/presentation/letters_screen.dart';
import '../../features/offline/presentation/outbox_screen.dart';
import '../../features/reminders/presentation/permission_screen.dart';
import '../../features/reminders/presentation/settings_screen.dart';
import '../../features/squads/presentation/squad_feed_screen.dart';
import '../../features/squads/presentation/squads_screen.dart';

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  final AuthRefreshNotifier refresh = ref.watch(authRefreshProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = auth.currentSession != null;
      final String location = state.matchedLocation;
      final bool isAuthRoute = location == '/signin' || location == '/signup';
      if (!signedIn) {
        return isAuthRoute ? null : '/signin';
      }
      if (isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (BuildContext context, GoRouterState state) =>
            const AuthScreen(mode: AuthMode.signIn),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (BuildContext context, GoRouterState state) =>
            const AuthScreen(mode: AuthMode.signUp),
      ),
      GoRoute(
        path: '/',
        name: 'gate',
        builder: (BuildContext context, GoRouterState state) =>
            const GateScreen(),
      ),
      GoRoute(
        path: '/contract/new',
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: '/today',
        name: 'today',
        builder: (BuildContext context, GoRouterState state) =>
            const TodayScreen(),
      ),
      GoRoute(
        path: '/ledger',
        name: 'ledger',
        builder: (BuildContext context, GoRouterState state) =>
            const LedgerScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications/intro',
        name: 'notifications-intro',
        builder: (BuildContext context, GoRouterState state) =>
            const PermissionScreen(),
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        builder: (BuildContext context, GoRouterState state) =>
            const InsightsScreen(),
      ),
      GoRoute(
        path: '/letters',
        name: 'letters',
        builder: (BuildContext context, GoRouterState state) =>
            const LettersScreen(),
      ),
      GoRoute(
        path: '/letters/write',
        name: 'letter-write',
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, String> query = state.uri.queryParameters;
          final int milestone = int.tryParse(query['milestone'] ?? '0') ?? 0;
          if (!letterMilestones.contains(milestone)) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: Text('Unknown letter milestone.')),
              ),
            );
          }
          return LetterWriteScreen(
            milestone: milestone,
            isRequired: query['required'] == 'true',
          );
        },
      ),
      GoRoute(
        path: '/letters/reveal/:milestone',
        name: 'letter-reveal',
        builder: (BuildContext context, GoRouterState state) {
          final int milestone =
              int.tryParse(state.pathParameters['milestone'] ?? '') ?? -1;
          if (!letterMilestones.contains(milestone)) {
            return const Scaffold(
              body: SafeArea(
                child: Center(child: Text('Unknown letter milestone.')),
              ),
            );
          }
          return LetterRevealScreen(milestone: milestone);
        },
      ),
      GoRoute(
        path: '/letters/final',
        name: 'final-receipt',
        builder: (BuildContext context, GoRouterState state) =>
            const FinalReceiptScreen(),
      ),
      GoRoute(
        path: '/outbox',
        name: 'outbox',
        builder: (BuildContext context, GoRouterState state) =>
            const OutboxScreen(),
      ),
      GoRoute(
        path: '/squads',
        name: 'squads',
        builder: (BuildContext context, GoRouterState state) =>
            const SquadsScreen(),
      ),
      GoRoute(
        path: '/squads/:id',
        name: 'squad-feed',
        builder: (BuildContext context, GoRouterState state) {
          return SquadFeedScreen(
            squadId: state.pathParameters['id'] ?? '',
            squadName: state.uri.queryParameters['name'],
          );
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
});
