// Reminder screen smoke tests with fakes (no plugins, no Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/presentation/auth_providers.dart';
import 'package:receipts/features/contract/data/contract_repository.dart';
import 'package:receipts/features/contract/domain/contract_draft.dart';
import 'package:receipts/features/contract/domain/contract_models.dart';
import 'package:receipts/features/contract/presentation/contract_providers.dart';
import 'package:receipts/features/reminders/data/notification_service.dart';
import 'package:receipts/features/reminders/presentation/permission_screen.dart';
import 'package:receipts/features/reminders/presentation/reminder_providers.dart';
import 'package:receipts/features/reminders/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fakes.dart';

class _FakeContracts implements ContractRepository {
  @override
  Future<List<Contract>> fetchContracts() async => <Contract>[];

  @override
  Future<Contract?> fetchActiveContract() async => Contract(
    id: 'contract-1',
    userId: 'user-1',
    startDate: DateTime.utc(2026, 10, 1),
    endDate: DateTime.utc(2026, 12, 30),
    mode: ContractModeDto.hard,
    status: ContractStatus.active,
    kindRecoveriesUsed: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  @override
  Future<List<Commitment>> fetchCommitments(String contractId) async =>
      <Commitment>[
        Commitment(
          id: 'c1',
          contractId: 'contract-1',
          userId: 'user-1',
          title: 'Run 20 minutes',
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ];

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

  @override
  Future<void> retireCommitment({
    required String commitmentId,
    required String contractId,
    required String reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ContractChange>> fetchContractChanges(String contractId) async {
    return <ContractChange>[];
  }
}

class _FakeNotifications implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> notificationsEnabled() async => false;

  @override
  Future<bool> requestNotificationsPermission() async => true;

  @override
  Future<bool> canScheduleExact() async => false;

  @override
  Future<void> requestExactAlarms() async {}

  @override
  Future<bool> schedule({
    required int id,
    required DateTime localFireTime,
    required String title,
    required String body,
    required bool exact,
    String? payload,
  }) async {
    return true;
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<int> pendingCount() async => 0;
}

Widget _harness(Widget child) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(initialUserId: 'user-1'),
      ),
      contractRepositoryProvider.overrideWithValue(_FakeContracts()),
      notificationServiceProvider.overrideWithValue(_FakeNotifications()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('settings shows status, quiet hours, tone, toggles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Quiet hours'), findsOneWidget);
    expect(find.text('Tone'), findsOneWidget);
    expect(find.textContaining('Off — no reminders'), findsOneWidget);

    // The toggle section sits below the fold in the test viewport.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Per-commitment reminders'), findsOneWidget);
    expect(find.text('Run 20 minutes'), findsOneWidget);
  });

  testWidgets('permission flow explains then offers honest fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(const PermissionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Reminders keep the contract honest.'), findsOneWidget);
    expect(find.textContaining('no true alarms'), findsOneWidget);

    await tester.tap(find.text('Enable reminders'));
    await tester.pumpAndSettle();

    // Fake grants notifications but denies exact alarms.
    expect(find.text('Approximate timing only.'), findsOneWidget);
    expect(find.text('Continue with approximate times'), findsOneWidget);
  });
}
