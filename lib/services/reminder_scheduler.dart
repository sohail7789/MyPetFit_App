import 'package:flutter/foundation.dart';

import 'reminder_gateway.dart';
import 'reminder_schedule.dart';

/// Brings the operating system's pending reminders in line with a plan.
///
/// **Cancel everything, then schedule the plan.** Reconciling item by item
/// would mean tracking what is currently pending and diffing against it, and
/// any drift between that record and the OS shows up as either a duplicate
/// notification or a reminder that will not switch off. Cancelling first
/// makes both impossible by construction: what the OS holds afterwards is
/// exactly the plan, and an empty plan leaves nothing pending.
///
/// The cost is re-registering a handful of alarms whenever anything changes,
/// which is a few platform calls on a list bounded by the number of pets.
class ReminderScheduler {
  ReminderScheduler(this._gateway);

  final ReminderGateway _gateway;

  /// The plan currently registered with the OS, or null before the first
  /// apply. Used to skip no-op reconciles.
  List<ScheduledReminder>? _applied;

  /// Serialises applies. Two overlapping reconciles would interleave a
  /// cancel with the other's schedules and leave the OS holding a subset.
  Future<void> _inFlight = Future.value();

  @visibleForTesting
  List<ScheduledReminder>? get appliedPlan => _applied;

  /// Applies [plan], replacing whatever was pending.
  ///
  /// An empty plan is the disable path and still runs the cancel — that is
  /// the point of it — unless nothing was scheduled to begin with.
  ///
  /// Identical plans are dropped. The pet and quiz providers notify on every
  /// edit, sync and selection change, and re-registering the same alarms on
  /// each of those would be a stream of platform calls that changes nothing.
  Future<void> apply(List<ScheduledReminder> plan) {
    final previous = _applied;
    if (previous != null && _sameAs(previous, plan)) return _inFlight;

    _applied = List.unmodifiable(plan);

    return _inFlight = _inFlight.then((_) async {
      await _gateway.cancelAll();
      for (final reminder in plan) {
        await _gateway.schedule(reminder);
      }
    });
  }

  static bool _sameAs(List<ScheduledReminder> a, List<ScheduledReminder> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Asks for permission, for the moment a reminder is switched on.
  Future<bool> requestPermission() => _gateway.requestPermission();

  /// Drops everything pending, for sign-out and account deletion.
  ///
  /// Forgets the memoised plan too, so the next [apply] is not mistaken for
  /// a no-op against a schedule that no longer exists.
  Future<void> cancelAll() {
    _applied = null;
    return _inFlight = _inFlight.then((_) => _gateway.cancelAll());
  }
}
