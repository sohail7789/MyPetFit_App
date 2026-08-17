import 'package:flutter/foundation.dart';

import '../analytics/models/assessment_cadence.dart';
import '../models/pet_info.dart';
import '../models/score_result.dart';

/// One reminder the app intends the operating system to deliver.
@immutable
class ScheduledReminder {
  /// The pet the reminder is about. Reminders are per pet because the
  /// cadence is: two animals assessed a month apart fall due a month apart.
  final String petId;

  final String petName;

  /// The local instant the notification should fire.
  final DateTime at;

  const ScheduledReminder({
    required this.petId,
    required this.petName,
    required this.at,
  });

  /// A stable, non-negative notification id.
  ///
  /// Only has to be stable within a reconcile — the scheduler cancels
  /// everything it owns before re-scheduling, so nothing depends on this
  /// surviving a restart.
  int get id => petId.hashCode & 0x7fffffff;

  String get title => 'Time to check in on $petName';

  String get body =>
      "$petName's last fitness assessment is 3 months old. Take it again to "
      'see how they are tracking.';

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.petId == petId &&
      other.petName == petName &&
      other.at == at;

  @override
  int get hashCode => Object.hash(petId, petName, at);

  @override
  String toString() => 'ScheduledReminder($petName, $at)';
}

/// The hour a reminder lands on, local time.
///
/// Mid-morning rather than midnight: a wellness nudge that wakes a phone at
/// 00:00 on the due date reads as a fault, not a reminder.
const int kReminderHour = 9;

/// What should be scheduled, given the current state of the app.
///
/// Pure and clock-free — [now] is supplied — so the policy can be tested
/// without a platform, which is the whole reason it is separated from the
/// gateway that talks to the OS.
///
/// Three rules, each of which exists to avoid a notification that would be
/// wrong rather than merely absent:
///
/// * Nothing at all while [enabled] is false. A disabled reminder must not
///   merely be hidden; it must not be pending with the OS either.
/// * Nothing for a pet that has never been assessed. There is no cadence to
///   count from, and the dashboard already invites a first assessment.
/// * Nothing for a date that is not in the future. A retake that is already
///   due is the in-app banner's business; the OS cannot deliver a past
///   instant, and rounding one up to "now" would fire a notification the
///   moment the toggle is switched on.
List<ScheduledReminder> planRetakeReminders({
  required bool enabled,
  required List<PetInfo> pets,
  required ScoreResult? Function(String petId) latestFor,
  required DateTime now,
  AssessmentCadence cadence = AssessmentCadence.standard,
}) {
  if (!enabled) return const [];

  final plan = <ScheduledReminder>[];

  for (final pet in pets) {
    final latest = latestFor(pet.id);
    if (latest == null) continue;

    final due = cadence.dueFrom(latest.completedAt, now: now);
    if (due == null) continue;

    // `dueOn` is a UTC-anchored local calendar date; its components are the
    // date the owner would read off a calendar, so they are rebuilt here as
    // a local instant rather than converted from UTC.
    final at = DateTime(
      due.dueOn.year,
      due.dueOn.month,
      due.dueOn.day,
      kReminderHour,
    );

    if (!at.isAfter(now)) continue;

    plan.add(
      ScheduledReminder(petId: pet.id, petName: pet.name, at: at),
    );
  }

  return List.unmodifiable(plan);
}
