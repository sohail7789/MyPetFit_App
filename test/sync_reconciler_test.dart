import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/services/sync_reconciler.dart';

/// A stand-in record, so these assert the rules rather than any one model.
/// Public because the helpers below expose it in their signatures.
class Rec {
  final String id;
  final String value;
  final DateTime updatedAt;

  const Rec(this.id, this.value, this.updatedAt);
}

DateTime at(int day) => DateTime.utc(2026, 1, day);

Reconciliation<Rec> run(List<Rec> local, List<Rec> cloud) =>
    reconcileCollection<Rec>(
      local: local,
      cloud: cloud,
      idOf: (r) => r.id,
      updatedAtOf: (r) => r.updatedAt,
      sameContent: (a, b) => a.value == b.value,
    );

void main() {
  group('the approved rules', () {
    test('cloud newer replaces local', () {
      final out = run(
        [Rec('a', 'local', at(1))],
        [Rec('a', 'cloud', at(2))],
      );

      expect(out.resolved.single.value, 'cloud');
      expect(out.toUpload, isEmpty);
      expect(out.outcomes['a'], SyncOutcome.tookCloud);
    });

    test('local newer is kept and queued', () {
      final out = run(
        [Rec('a', 'local', at(2))],
        [Rec('a', 'cloud', at(1))],
      );

      expect(out.resolved.single.value, 'local');
      expect(out.toUpload.single.value, 'local');
      expect(out.outcomes['a'], SyncOutcome.keptLocal);
    });

    test('equal and identical does nothing', () {
      final out = run(
        [Rec('a', 'same', at(1))],
        [Rec('a', 'same', at(1))],
      );

      expect(out.toUpload, isEmpty);
      expect(out.outcomes['a'], SyncOutcome.unchanged);
      expect(out.warnings, isEmpty);
    });

    test('only in cloud is adopted', () {
      final out = run([], [Rec('a', 'cloud', at(1))]);

      expect(out.resolved.single.value, 'cloud');
      expect(out.toUpload, isEmpty);
      expect(out.outcomes['a'], SyncOutcome.adopted);
    });

    test('only local is kept and queued', () {
      final out = run([Rec('a', 'local', at(1))], []);

      expect(out.resolved.single.value, 'local');
      expect(out.toUpload.single.value, 'local');
      expect(out.outcomes['a'], SyncOutcome.uploadedNew);
    });

    test('equal timestamp with different content: cloud wins, and warns', () {
      final out = run(
        [Rec('a', 'local', at(1))],
        [Rec('a', 'cloud', at(1))],
      );

      // Deterministic on every device beats a merge nobody can predict.
      expect(out.resolved.single.value, 'cloud');
      expect(out.toUpload, isEmpty);
      expect(out.warnings, hasLength(1));
      expect(out.warnings.single, contains('clock skew'));
    });
  });

  group('migration', () {
    test('a record with no updatedAt loses to one that has it', () {
      // Undated local, dated cloud — the cloud copy is real data and must
      // not be overwritten by a cache from before timestamps existed.
      final out = run(
        [Rec('a', 'legacy-local', kUnknownUpdatedAt)],
        [Rec('a', 'cloud', at(1))],
      );

      expect(out.resolved.single.value, 'cloud');
    });

    test('undated on both sides is a content comparison, not a coin toss', () {
      final out = run(
        [Rec('a', 'local', kUnknownUpdatedAt)],
        [Rec('a', 'cloud', kUnknownUpdatedAt)],
      );

      expect(out.resolved.single.value, 'cloud');
      expect(out.warnings, hasLength(1));
    });

    test('the sentinel is the epoch, in UTC', () {
      expect(kUnknownUpdatedAt.millisecondsSinceEpoch, 0);
      expect(kUnknownUpdatedAt.isUtc, isTrue);
    });
  });

  group('collections', () {
    test('merges both sides, keeping local order then cloud-only rows', () {
      final out = run(
        [Rec('a', 'a-local', at(2)), Rec('b', 'b-local', at(1))],
        [Rec('b', 'b-cloud', at(3)), Rec('c', 'c-cloud', at(1))],
      );

      expect(out.resolved.map((r) => r.id), ['a', 'b', 'c']);
      expect(out.resolved.map((r) => r.value),
          ['a-local', 'b-cloud', 'c-cloud']);
      // Only 'a' is ahead of the cloud.
      expect(out.toUpload.map((r) => r.id), ['a']);
    });

    test('comparison is timezone-independent', () {
      // The same instant expressed locally and in UTC must not read as a
      // conflict just because the DateTime objects differ.
      final utc = DateTime.utc(2026, 1, 2, 12);
      final out = reconcileCollection<Rec>(
        local: [Rec('a', 'same', utc.toLocal())],
        cloud: [Rec('a', 'same', utc)],
        idOf: (r) => r.id,
        updatedAtOf: (r) => r.updatedAt,
        sameContent: (a, b) => a.value == b.value,
      );

      expect(out.outcomes['a'], SyncOutcome.unchanged);
      expect(out.warnings, isEmpty);
    });

    test('an empty pair resolves to nothing', () {
      final out = run([], []);
      expect(out.resolved, isEmpty);
      expect(out.toUpload, isEmpty);
      expect(out.hasUploads, isFalse);
    });
  });

  group('single records', () {
    test('local-only is queued', () {
      final out = reconcileSingle<Rec>(
        local: Rec('owner', 'local', at(2)),
        cloud: null,
        updatedAtOf: (r) => r.updatedAt,
        id: 'owner',
      );

      expect(out.resolved.single.value, 'local');
      expect(out.toUpload, hasLength(1));
    });

    test('cloud-only is adopted', () {
      final out = reconcileSingle<Rec>(
        local: null,
        cloud: Rec('owner', 'cloud', at(2)),
        updatedAtOf: (r) => r.updatedAt,
        id: 'owner',
      );

      expect(out.resolved.single.value, 'cloud');
      expect(out.toUpload, isEmpty);
    });

    test('neither side resolves to nothing', () {
      final out = reconcileSingle<Rec>(
        local: null,
        cloud: null,
        updatedAtOf: (r) => r.updatedAt,
      );

      expect(out.resolved, isEmpty);
    });
  });

  group('recovery after process death', () {
    test('an unsynced local edit is re-queued by timestamp alone', () {
      // The queue did not survive the kill. Nothing replays it — the
      // timestamps say local is ahead, so the upload is derived rather
      // than remembered.
      final out = run(
        [Rec('pet-1', 'edited offline', at(5))],
        [Rec('pet-1', 'stale', at(3))],
      );

      expect(out.toUpload.single.value, 'edited offline');
      expect(out.resolved.single.value, 'edited offline');
    });
  });
}
