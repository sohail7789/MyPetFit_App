import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart' show NotSignedInException;

/// Pushes local changes to Firestore without letting them block anything.
///
/// The app is offline-first: a change is applied in memory, written to
/// SharedPreferences, and shown immediately. The cloud write happens after
/// that and off the critical path, so losing the network delays a sync — it
/// never fails an assessment, an owner edit or a saved pet.
///
/// ## Guarantees
///
/// * **Per record, in order.** Writes for one key are serialised; a second
///   edit never overtakes the first. Different keys run concurrently, which
///   is safe here because each maps to its own document.
/// * **Latest wins.** Only the newest write per key is kept, so three edits
///   made offline replay once, with the final value.
/// * **Retry-safe.** Every write is a `set()` against a deterministic
///   document id, so replaying one cannot duplicate a record.
/// * **Session-bound.** A write that outlives its sign-in is dropped rather
///   than retried, so it can never land under the next account.
///
/// ## Not guaranteed
///
/// The queue lives in memory. If the process is killed while a write is
/// pending, that write is lost — the local data survives, but the cloud is
/// not told until the record is edited again. See `retryPendingSyncs`.
mixin CloudSync on ChangeNotifier {
  /// The newest unsent write per record. Keyed so editing the same pet three
  /// times while offline replays once, with the newest value, instead of
  /// three times with two stale ones.
  final Map<String, Future<void> Function()> _pending = {};

  /// Keys with a drain loop already running. Without this a second edit
  /// started a second concurrent write for the same document, and if the
  /// older one happened to land last it silently won.
  final Set<String> _draining = {};

  Object? _lastSyncError;

  /// Why the last cloud write failed, or null if the last one succeeded.
  Object? get lastSyncError => _lastSyncError;

  /// True while any change has been saved locally but not yet accepted by
  /// Firestore.
  bool get hasPendingSync => _pending.isNotEmpty;

  int get pendingSyncCount => _pending.length;

  /// Records [write] as the newest pending change for [key] and starts
  /// sending it.
  ///
  /// Returns immediately. Deliberately not awaited by callers — awaiting it
  /// would reintroduce exactly the coupling this exists to remove.
  void queueSync(String key, Future<void> Function() write) {
    _pending[key] = write;
    unawaited(_drain(key));
  }

  /// Sends whatever is pending for [key], one write at a time, until the
  /// queue for that key is empty or a write fails.
  Future<void> _drain(String key) async {
    // A loop is already running for this key; it will pick up whatever was
    // just queued when the in-flight write finishes.
    if (_draining.contains(key)) return;
    _draining.add(key);

    try {
      while (_pending.containsKey(key)) {
        final write = _pending[key]!;
        try {
          await write();
        } on NotSignedInException {
          // Discarded, not retried. This write belongs to a session that has
          // ended; replaying it would either fail forever or, worse, land
          // under whoever signs in next. Not recorded as a sync error
          // either — there is nothing for the user to act on.
          _pending.remove(key);
          if (kDebugMode) {
            debugPrint('Cloud sync dropped for "$key": no signed-in user');
          }
          return;
        } catch (error, stack) {
          // Left in _pending on purpose: the local write already succeeded,
          // and the record should still reach the cloud on a later attempt.
          _lastSyncError = error;
          if (kDebugMode) {
            debugPrint('Cloud sync failed for "$key": $error');
            debugPrintStack(stackTrace: stack);
          }
          notifyListeners();
          return;
        }

        // Anything queued while that was in flight is newer, so loop and
        // send it rather than dropping it.
        if (identical(_pending[key], write)) _pending.remove(key);
      }

      if (_lastSyncError != null && _pending.isEmpty) {
        _lastSyncError = null;
        notifyListeners();
      }
    } finally {
      _draining.remove(key);
    }
  }

  /// Replays everything still waiting. Safe to call when nothing is.
  ///
  /// The natural caller is a reconnect or a "retry" affordance; there is no
  /// automatic timer, so a failed write waits until something asks.
  Future<void> retryPendingSyncs() async {
    for (final key in _pending.keys.toList()) {
      await _drain(key);
    }
  }

  /// Drops queued writes. Called on sign-out, so one account's unsynced
  /// changes are never pushed under the next account's credentials.
  void clearPendingSyncs() {
    if (_pending.isEmpty && _lastSyncError == null) return;
    _pending.clear();
    _lastSyncError = null;
    notifyListeners();
  }
}
