import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/data/auth_repository.dart';
import 'package:receipts/features/offline/data/local_cache.dart';
import 'package:receipts/features/offline/data/local_database.dart';
import 'package:receipts/features/reminders/data/settings_store.dart';
import 'package:receipts/features/reminders/domain/message_engine.dart';
import 'package:receipts/features/reminders/presentation/settings_screen.dart'
    show isDeleteConfirmed;
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fakes.dart';

Future<LocalCache> _memoryCache() async {
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return LocalCache(db);
}

void main() {
  group('isDeleteConfirmed', () {
    test('only exact DELETE confirms', () {
      expect(isDeleteConfirmed('DELETE'), isTrue);
      expect(isDeleteConfirmed('  DELETE  '), isTrue);
      expect(isDeleteConfirmed('delete'), isFalse);
      expect(isDeleteConfirmed(''), isFalse);
      expect(isDeleteConfirmed('DELET'), isFalse);
    });
  });

  group('delete flow with fakes', () {
    test('success clears server (fake), cache, and settings', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final LocalCache cache = await _memoryCache();

      // Seed user-1 cache + settings like a real device would hold.
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run',
        day: DateTime.utc(2026, 10, 5),
      );
      final ReminderSettingsStore store = ReminderSettingsStore(
        prefs,
        userId: 'user-1',
      );
      await store.save(const ReminderSettings(tone: ReminderTone.blunt));

      final FakeAuthRepository auth = FakeAuthRepository(
        initialUserId: 'user-1',
      );
      bool deleted = false;
      auth.onDeleteAccount = () async {
        deleted = true;
      };

      // The same order the Settings danger zone uses: server delete, local
      // wipe, then session end.
      await auth.deleteAccount();
      expect(deleted, isTrue);
      await cache.clearUser('user-1');
      await store.delete();
      auth.signOutAs();

      expect(await cache.pendingOutbox('user-1'), isEmpty);
      expect(await cache.readContract('user-1'), isNull);
      expect(store.load().tone, ReminderTone.firm);
      expect(auth.currentSession, isNull);
    });

    test('delete failure keeps local data for retry', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalCache cache = await _memoryCache();
      await cache.enqueueCheckIn(
        userId: 'user-1',
        contractId: 'contract-1',
        commitmentId: 'c1',
        commitmentTitle: 'Run',
        day: DateTime.utc(2026, 10, 5),
      );

      final FakeAuthRepository auth = FakeAuthRepository(
        initialUserId: 'user-1',
      );
      auth.onDeleteAccount = () async {
        throw const AuthFailure('Delete failed. Try again.');
      };

      await expectLater(auth.deleteAccount(), throwsA(isA<AuthFailure>()));
      // Nothing wiped: the user can retry.
      expect(await cache.pendingOutbox('user-1'), hasLength(1));
      expect(auth.currentSession, isNotNull);
    });
  });

  group('clearUser scope', () {
    test('removes only that user\u2019s rows', () async {
      final LocalCache cache = await _memoryCache();
      for (final String user in <String>['user-1', 'user-2']) {
        await cache.enqueueCheckIn(
          userId: user,
          contractId: 'contract-1',
          commitmentId: 'c1',
          commitmentTitle: 'Run',
          day: DateTime.utc(2026, 10, 5),
        );
      }
      await cache.clearUser('user-1');
      expect(await cache.pendingOutbox('user-1'), isEmpty);
      expect(await cache.pendingOutbox('user-2'), hasLength(1));
    });
  });
}
