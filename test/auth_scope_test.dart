// Multi-user isolation regression tests: auth transitions A -> null -> B
// must refetch per user and never serve one user's cached rows to another.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/presentation/auth_providers.dart';
import 'package:receipts/features/contract/data/contract_repository.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';
import 'package:receipts/features/contract/presentation/contract_providers.dart';
import 'package:receipts/features/reminders/data/settings_store.dart';
import 'package:receipts/features/reminders/domain/message_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fakes.dart';

/// Simulates server-side RLS: only serves rows for the currently "signed-in"
/// user id, set alongside the fake auth session in each test step.
class FakeContracts implements ContractRepository {
  String? userId;
  int activeFetches = 0;

  Contract _contractA() {
    return Contract(
      id: 'contract-a',
      userId: 'user-a',
      startDate: DateTime.utc(2026, 10, 1),
      endDate: DateTime.utc(2026, 12, 30),
      mode: ContractModeDto.kind,
      status: ContractStatus.active,
      kindRecoveriesUsed: 0,
      createdAt: DateTime.utc(2026, 10, 1),
    );
  }

  @override
  Future<List<Contract>> fetchContracts() async =>
      userId == 'user-a' ? <Contract>[_contractA()] : <Contract>[];

  @override
  Future<Contract?> fetchActiveContract() async {
    activeFetches += 1;
    return userId == 'user-a' ? _contractA() : null;
  }

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async {
    if (userId != 'user-a' || contractId != 'contract-a') {
      return <Commitment>[];
    }
    return <Commitment>[
      Commitment(
        id: 'ca-1',
        contractId: 'contract-a',
        userId: 'user-a',
        title: 'Run 20 minutes',
        sortOrder: 0,
        createdAt: DateTime.utc(2026, 10, 1),
      ),
      Commitment(
        id: 'ca-2',
        contractId: 'contract-a',
        userId: 'user-a',
        title: 'Read 10 pages',
        sortOrder: 1,
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    ];
  }

  @override
  Future<String> createContract({
    required DateTime startDate,
    required ContractModeDto mode,
    required List<CommitmentDraft> commitments,
    String reason = 'initial contract lock',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Pause>> fetchPauses(String contractId) async => <Pause>[];

  @override
  Future<void> declarePause({
    required String contractId,
    required String type,
    required DateTime startDay,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> endPause({
    required String pauseId,
    required DateTime endDay,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  /// Lets broadcast auth events reach providers before assertions read.
  /// (The first `.future` read waits on its own; later reads would otherwise
  /// resolve with the pre-event value.)
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test(
    'auth switch refetches per user; B sees onboarding, never A rows',
    () async {
      final FakeAuthRepository auth = FakeAuthRepository();
      final FakeContracts contracts = FakeContracts();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          contractRepositoryProvider.overrideWithValue(contracts),
        ],
      );
      addTearDown(container.dispose);
      // Hold a listener so autoDispose cannot churn between reads: every
      // refetch below must be caused by the auth transition, not by disposal.
      final ProviderSubscription<AsyncValue<Contract?>> sub = container.listen(
        activeContractProvider,
        (prev, next) {},
      );
      addTearDown(sub.close);

      // Subscribe before emitting: broadcast streams drop pre-listen events.
      container.read(currentUserIdProvider);

      // User A signs in: contract + commitments load, one query each.
      auth.signInAs('user-a');
      contracts.userId = 'user-a';
      expect(await container.read(currentUserIdProvider.future), 'user-a');
      expect(
        (await container.read(activeContractProvider.future))?.id,
        'contract-a',
      );
      expect(contracts.activeFetches, 1);
      final List<String> titlesA = (await container.read(
        commitmentsProvider('contract-a').future,
      )).map((Commitment c) => c.title).toList();
      expect(titlesA, contains('Run 20 minutes'));

      // Re-reading without an auth change must not refetch.
      await container.read(activeContractProvider.future);
      expect(contracts.activeFetches, 1);

      // Sign out: identity goes null. The provider re-runs but short-circuits
      // to null without querying (fetch count unchanged), so no signed-out
      // read can ever serve cached rows.
      auth.signOutAs();
      contracts.userId = null;
      await settle();
      expect(await container.read(currentUserIdProvider.future), isNull);
      expect(await container.read(activeContractProvider.future), isNull);
      expect(contracts.activeFetches, 1);

      // User B signs in: fresh B-scoped query, no contract -> onboarding
      // state, and none of A's titles anywhere.
      auth.signInAs('user-b');
      contracts.userId = 'user-b';
      await settle();
      expect(await container.read(currentUserIdProvider.future), 'user-b');
      expect(await container.read(activeContractProvider.future), isNull);
      expect(contracts.activeFetches, 2);
      final List<Commitment> titlesB = await container.read(
        commitmentsProvider('contract-a').future,
      );
      expect(titlesB, isEmpty);

      // Back to A: a fresh A-scoped query restores A's state.
      auth.signInAs('user-a');
      contracts.userId = 'user-a';
      await settle();
      expect(
        (await container.read(activeContractProvider.future))?.id,
        'contract-a',
      );
      expect(contracts.activeFetches, 3);
    },
  );

  test('reminder settings are scoped per user', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final ReminderSettingsStore storeA = ReminderSettingsStore(
      prefs,
      userId: 'user-a',
    );
    await storeA.save(
      const ReminderSettings(
        tone: ReminderTone.blunt,
        permissionAsked: true,
        disabledCommitmentIds: <String>{'ca-1'},
      ),
    );

    final ReminderSettings loadedB = ReminderSettingsStore(
      prefs,
      userId: 'user-b',
    ).load();
    expect(loadedB.tone, ReminderTone.firm);
    expect(loadedB.permissionAsked, isFalse);
    expect(loadedB.disabledCommitmentIds, isEmpty);

    final ReminderSettings loadedA = storeA.load();
    expect(loadedA.tone, ReminderTone.blunt);
    expect(loadedA.permissionAsked, isTrue);
    expect(loadedA.disabledCommitmentIds, contains('ca-1'));
  });
}
