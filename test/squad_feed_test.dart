// Squad feed + nudge tests with fakes (no Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/presentation/auth_providers.dart';
import 'package:receipts/features/squads/data/squad_repository.dart';
import 'package:receipts/features/squads/domain/squad_models.dart';
import 'package:receipts/features/squads/presentation/squad_feed_screen.dart';
import 'package:receipts/features/squads/presentation/squad_providers.dart';
import 'package:receipts/features/squads/presentation/squads_screen.dart';

import 'test_fakes.dart';

class FakeSquads implements SquadRepository {
  final List<(String, String)> nudgesSent = <(String, String)>[];

  @override
  Future<List<Squad>> fetchMySquads() async => <Squad>[
    Squad(
      id: 'squad-1',
      name: 'Winter Arc',
      createdAt: DateTime.utc(2026, 10, 1),
    ),
  ];

  @override
  Future<({String id, String inviteCode})> createSquad(String name) async {
    throw UnimplementedError();
  }

  @override
  Future<String> joinSquad(String inviteCode) async {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveSquad(String squadId) async {}

  @override
  Future<List<SquadFeedRow>> fetchFeed(String squadId) async => <SquadFeedRow>[
    const SquadFeedRow(
      memberUserId: 'u1',
      displayName: 'Asha',
      dayNumber: 12,
      todayStatus: 'kept',
      currentStreak: 5,
      missedCount: 1,
    ),
    const SquadFeedRow(
      memberUserId: 'u2',
      displayName: 'Bala',
      dayNumber: 12,
      todayStatus: 'missed',
      currentStreak: 0,
      missedCount: 4,
    ),
    const SquadFeedRow(
      memberUserId: 'u3',
      displayName: 'Squadmate',
      dayNumber: null,
      todayStatus: null,
      currentStreak: null,
      missedCount: null,
    ),
  ];

  @override
  Future<Set<String>> fetchNudgedToday(String squadId) async => <String>{'u2'};

  @override
  Future<void> sendNudge({
    required String squadId,
    required String toUserId,
  }) async {
    nudgesSent.add((squadId, toUserId));
  }
}

Widget _harness(Widget child, FakeSquads squads) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(initialUserId: 'me'),
      ),
      squadRepositoryProvider.overrideWithValue(squads),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('squads list shows my squads', (WidgetTester tester) async {
    await tester.pumpWidget(_harness(const SquadsScreen(), FakeSquads()));
    await tester.pumpAndSettle();

    expect(find.text('Winter Arc'), findsOneWidget);
  });

  testWidgets('feed shows misses and honest nudge states', (
    WidgetTester tester,
  ) async {
    final FakeSquads squads = FakeSquads();
    await tester.pumpWidget(
      _harness(
        const SquadFeedScreen(squadId: 'squad-1', squadName: 'Winter Arc'),
        squads,
      ),
    );
    await tester.pumpAndSettle();

    // Misses are visible with names and streaks; notes/titles never render
    // (the model has no such fields by construction).
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Bala'), findsOneWidget);
    expect(find.text('missed'), findsOneWidget);
    expect(find.text('kept'), findsOneWidget);

    // Already-nudged member shows sent state; others can be nudged once.
    expect(find.text('Nudged today'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Nudge').first);
    await tester.pumpAndSettle();
    expect(squads.nudgesSent, [('squad-1', 'u1')]);
  });

  test('feed provider returns only the allowed columns', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUserId: 'me'),
        ),
        squadRepositoryProvider.overrideWithValue(FakeSquads()),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<AsyncValue<List<SquadFeedRow>>> sub = container
        .listen(squadFeedProvider('squad-1'), (prev, next) {});
    addTearDown(sub.close);

    final List<SquadFeedRow> rows = await container.read(
      squadFeedProvider('squad-1').future,
    );
    expect(rows, hasLength(3));
    expect(
      rows
          .where((SquadFeedRow r) => r.todayStatus == 'missed')
          .map((r) => r.displayName),
      ['Bala'],
    );
  });
}
