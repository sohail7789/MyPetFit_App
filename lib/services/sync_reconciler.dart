/// Decides what local state should become, and what needs uploading, when a
/// device's cached records meet the cloud's.
///
/// Pure by construction: no Flutter, no Firestore, no SharedPreferences, no
/// clock. Everything it needs arrives as an argument and everything it
/// decides comes back in the result, so the rules can be exercised directly
/// instead of through a provider and a network stack.
library;

/// The instant a record with no `updatedAt` is treated as having.
///
/// Records written before timestamps existed — in the local cache or in
/// Firestore — decode to this. Being older than any real edit, it means the
/// first reconcile after upgrading resolves in favour of whatever the other
/// side has rather than silently overwriting real cloud data with a stale
/// local copy.
final DateTime kUnknownUpdatedAt =
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// What happened to one record.
enum SyncOutcome {
  /// Cloud was newer, or the two were equal but differed. Local replaced.
  tookCloud,

  /// Local was newer. Kept, and queued for upload.
  keptLocal,

  /// Present only in the cloud. Adopted locally.
  adopted,

  /// Present only locally. Kept, and queued for upload.
  uploadedNew,

  /// Same timestamp, same content. Nothing to do.
  unchanged,
}

/// The result of reconciling a collection.
class Reconciliation<T> {
  /// What local state should become — the winner for every id seen on
  /// either side.
  final List<T> resolved;

  /// The subset of [resolved] that the cloud does not yet have, or has an
  /// older copy of. Queue these.
  final List<T> toUpload;

  /// Same-timestamp-different-content collisions, described for logging.
  /// Resolved in the cloud's favour; surfaced because a recurring one points
  /// at a clock problem rather than a normal edit.
  final List<String> warnings;

  /// Per-id outcomes, for tests and diagnostics.
  final Map<String, SyncOutcome> outcomes;

  const Reconciliation({
    required this.resolved,
    required this.toUpload,
    this.warnings = const [],
    this.outcomes = const {},
  });

  bool get hasUploads => toUpload.isNotEmpty;
}

/// Reconciles a keyed collection — pets today, anything with an id later.
///
/// Rules, in the order they are checked:
///
/// | Situation                        | Result                        |
/// |----------------------------------|-------------------------------|
/// | only in cloud                    | adopt                         |
/// | only local                       | keep, queue upload            |
/// | cloud newer                      | replace local                 |
/// | local newer                      | keep, queue upload            |
/// | equal, same content              | nothing                       |
/// | equal, different content         | cloud wins, warn              |
///
/// Equal-but-different resolves to the cloud on purpose. It is the shared
/// copy, so choosing it is the same decision on every device; choosing local
/// would leave two devices permanently disagreeing, each certain it was
/// right. Determinism beats a merge nobody can predict.
Reconciliation<T> reconcileCollection<T>({
  required List<T> local,
  required List<T> cloud,
  required String Function(T) idOf,
  required DateTime Function(T) updatedAtOf,
  bool Function(T local, T cloud)? sameContent,
}) {
  final localById = {for (final item in local) idOf(item): item};
  final cloudById = {for (final item in cloud) idOf(item): item};

  final resolved = <T>[];
  final toUpload = <T>[];
  final warnings = <String>[];
  final outcomes = <String, SyncOutcome>{};

  // Local order first so a returning user's list does not reshuffle, then
  // anything the cloud knows about that this device does not.
  final ids = <String>[
    ...localById.keys,
    ...cloudById.keys.where((id) => !localById.containsKey(id)),
  ];

  for (final id in ids) {
    final localItem = localById[id];
    final cloudItem = cloudById[id];

    if (localItem == null) {
      // Added on another device.
      resolved.add(cloudItem as T);
      outcomes[id] = SyncOutcome.adopted;
      continue;
    }

    if (cloudItem == null) {
      // Never synced — or deleted elsewhere, which this cannot tell apart.
      // See the deletion note in the class docs.
      resolved.add(localItem);
      toUpload.add(localItem);
      outcomes[id] = SyncOutcome.uploadedNew;
      continue;
    }

    final localAt = updatedAtOf(localItem).toUtc();
    final cloudAt = updatedAtOf(cloudItem).toUtc();

    if (cloudAt.isAfter(localAt)) {
      resolved.add(cloudItem);
      outcomes[id] = SyncOutcome.tookCloud;
    } else if (localAt.isAfter(cloudAt)) {
      resolved.add(localItem);
      toUpload.add(localItem);
      outcomes[id] = SyncOutcome.keptLocal;
    } else {
      final identical = sameContent?.call(localItem, cloudItem) ?? true;
      if (identical) {
        resolved.add(localItem);
        outcomes[id] = SyncOutcome.unchanged;
      } else {
        resolved.add(cloudItem);
        outcomes[id] = SyncOutcome.tookCloud;
        warnings.add(
          'Record "$id" differs with an identical updatedAt '
          '(${localAt.toIso8601String()}); took the cloud copy. Repeated '
          'occurrences suggest device clock skew.',
        );
      }
    }
  }

  return Reconciliation<T>(
    resolved: resolved,
    toUpload: toUpload,
    warnings: warnings,
    outcomes: outcomes,
  );
}

/// The single-record form, for the owner profile.
///
/// Same rules; "only in cloud" and "only local" collapse to adopting
/// whichever side has one.
Reconciliation<T> reconcileSingle<T>({
  required T? local,
  required T? cloud,
  required DateTime Function(T) updatedAtOf,
  bool Function(T local, T cloud)? sameContent,
  String id = 'record',
}) {
  return reconcileCollection<T>(
    local: local == null ? const [] : [local],
    cloud: cloud == null ? const [] : [cloud],
    idOf: (_) => id,
    updatedAtOf: updatedAtOf,
    sameContent: sameContent,
  );
}
