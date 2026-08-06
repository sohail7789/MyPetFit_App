import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/providers/cloud_sync.dart';
import 'package:mypetfit_app/services/firestore_service.dart'
    show NotSignedInException;
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal host for the mixin, so these assert the contract rather than any
/// one provider's use of it.
class _Syncer extends ChangeNotifier with CloudSync {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('cloud sync', () {
    test('a successful write leaves nothing pending', () async {
      final syncer = _Syncer();
      syncer.queueSync('owner', () async {});
      await Future<void>.delayed(Duration.zero);

      expect(syncer.hasPendingSync, isFalse);
      expect(syncer.lastSyncError, isNull);
    });

    test('queueSync returns before the write finishes', () async {
      final syncer = _Syncer();
      var finished = false;

      syncer.queueSync('owner', () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        finished = true;
      });

      // The whole point: callers carry on immediately. Awaiting the cloud
      // here is what made an assessment fail when Firestore was unreachable.
      expect(finished, isFalse);
      expect(syncer.hasPendingSync, isTrue);
    });

    test('a failed write is kept, not swallowed', () async {
      final syncer = _Syncer();
      syncer.queueSync('owner', () async => throw Exception('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(syncer.hasPendingSync, isTrue);
      expect(syncer.lastSyncError, isNotNull);
    });

    test('retry clears it once the write succeeds', () async {
      final syncer = _Syncer();
      var online = false;

      syncer.queueSync('owner', () async {
        if (!online) throw Exception('offline');
      });
      await Future<void>.delayed(Duration.zero);
      expect(syncer.hasPendingSync, isTrue);

      online = true;
      await syncer.retryPendingSyncs();

      expect(syncer.hasPendingSync, isFalse);
      expect(syncer.lastSyncError, isNull);
    });

    test('repeated edits to one record collapse to a single write', () async {
      final syncer = _Syncer();
      final written = <int>[];

      for (final value in [1, 2, 3]) {
        syncer.queueSync('pet-a', () async {
          if (value != 3) throw Exception('offline');
          written.add(value);
        });
      }
      await Future<void>.delayed(Duration.zero);
      await syncer.retryPendingSyncs();

      // Three offline edits to the same pet should not replay as three
      // writes, and certainly not with the two stale values.
      expect(written, [3]);
      expect(syncer.hasPendingSync, isFalse);
    });

    test('different records queue separately', () async {
      final syncer = _Syncer();
      syncer.queueSync('owner', () async => throw Exception('offline'));
      syncer.queueSync('pet-a', () async => throw Exception('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(syncer.pendingSyncCount, 2);
    });

    test('signing out drops the previous account unsynced writes', () async {
      final syncer = _Syncer();
      var written = false;

      syncer.queueSync('owner', () async {
        written = true;
        throw Exception('offline');
      });
      await Future<void>.delayed(Duration.zero);
      expect(syncer.hasPendingSync, isTrue);

      written = false;
      syncer.clearPendingSyncs();
      await syncer.retryPendingSyncs();

      // Replaying after a sign-out would write one account's data under the
      // next account's credentials.
      expect(written, isFalse);
      expect(syncer.hasPendingSync, isFalse);
    });

    test('one record never has two writes in flight at once', () async {
      final syncer = _Syncer();
      var concurrent = 0;
      var maxConcurrent = 0;
      final order = <int>[];

      for (final value in [1, 2, 3]) {
        syncer.queueSync('pet-a', () async {
          concurrent++;
          maxConcurrent = maxConcurrent > concurrent ? maxConcurrent : concurrent;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          order.add(value);
          concurrent--;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Two concurrent writes for one document means the older can land
      // last and silently win.
      expect(maxConcurrent, 1);
      // The first is already away when 2 and 3 arrive; 3 supersedes 2.
      expect(order, [1, 3]);
      expect(syncer.hasPendingSync, isFalse);
    });

    test('a write that outlives its session is dropped, not retried',
        () async {
      final syncer = _Syncer();
      var attempts = 0;

      syncer.queueSync('owner', () async {
        attempts++;
        throw const NotSignedInException();
      });
      await Future<void>.delayed(Duration.zero);

      // Nothing to retry and nothing to report: the write belongs to a
      // session that has ended, and replaying it would land under whoever
      // signs in next.
      expect(syncer.hasPendingSync, isFalse);
      expect(syncer.lastSyncError, isNull);

      await syncer.retryPendingSyncs();
      expect(attempts, 1);
    });

    test('a failure notifies, so a screen can surface it', () async {
      final syncer = _Syncer();
      var notifications = 0;
      syncer.addListener(() => notifications++);

      syncer.queueSync('owner', () async => throw Exception('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(notifications, greaterThan(0));
    });
  });
}
