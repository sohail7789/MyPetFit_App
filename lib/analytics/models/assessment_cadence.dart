/// Where a record stands against the retake cadence.
///
/// Three states rather than a signed number of days, because a signed number
/// is what produces "Due in -3 days". A magnitude that is always positive and
/// a state that says which way to read it cannot render that sentence at all
/// — the same discipline [TrendDirection.unknown] applies to a trend nobody
/// can claim.
enum AssessmentDueState {
  /// The assessment is still current.
  upcoming,

  /// Due on this very day.
  dueToday,

  /// The cadence has passed.
  overdue,
}

/// How far a record is from its next assessment.
///
/// [days] is never negative. Read it with [state]: days *until* due while
/// [AssessmentDueState.upcoming], days *since* due while
/// [AssessmentDueState.overdue], and zero on the day itself.
class AssessmentDue {
  /// The calendar date the next assessment falls due, in local terms.
  ///
  /// A date, not an instant: cadence is counted in days an owner recognises,
  /// and carrying a time of day would invite a countdown that changes at an
  /// arbitrary hour of the morning.
  final DateTime dueOn;

  final AssessmentDueState state;

  /// Whole days to or from [dueOn]. Always zero or more.
  final int days;

  const AssessmentDue({
    required this.dueOn,
    required this.state,
    required this.days,
  });

  /// True once an assessment is worth taking — today or overdue.
  bool get isDue => state != AssessmentDueState.upcoming;

  bool get isOverdue => state == AssessmentDueState.overdue;

  @override
  bool operator ==(Object other) =>
      other is AssessmentDue &&
      other.dueOn == dueOn &&
      other.state == state &&
      other.days == days;

  @override
  int get hashCode => Object.hash(dueOn, state, days);

  @override
  String toString() => 'AssessmentDue(${state.name}, $days days, $dueOn)';
}

/// How long an assessment stays current before another is worth taking.
///
/// **The one place the retake interval is stated.** It was previously a
/// private constant on the dashboard, prose in the report card and a line in
/// preferences; three copies of a number that must agree is three chances for
/// them to stop agreeing. A policy object rather than a bare `const int` so a
/// veterinary consumer can hold a tighter cadence for a convalescing animal
/// without forking the calculation.
///
/// Clock-free by construction: every method takes the instant to judge
/// against, so the domain never reads a clock and a test can hand it any day
/// it likes.
class AssessmentCadence {
  /// Days an assessment remains current.
  final int validDays;

  const AssessmentCadence({this.validDays = 90});

  /// The product's cadence: ninety days, matching the "retake in 3 months"
  /// the report card has always advised.
  static const AssessmentCadence standard = AssessmentCadence();

  /// Where [lastAssessmentAt] stands as of [now], or null when nothing has
  /// been assessed.
  ///
  /// Null rather than a zeroed value: a pet with no record is not overdue,
  /// and a caller that has to check a flag before trusting the number will
  /// eventually forget to.
  AssessmentDue? dueFrom(DateTime? lastAssessmentAt, {required DateTime now}) {
    if (lastAssessmentAt == null) return null;

    final today = _dayOf(now);

    // Clamped at zero, so a record synced from a handset whose clock runs
    // fast reads as assessed today rather than granting extra days. Matches
    // how the history timeline buckets a future timestamp and how
    // [StatisticsCalculator] clamps a tracking span.
    final elapsed = _daysBetween(_dayOf(lastAssessmentAt), today);
    final remaining = validDays - (elapsed < 0 ? 0 : elapsed);

    return AssessmentDue(
      // Counted forward from today rather than from the stored date, so the
      // due date agrees with [remaining] even when the clamp above moved it.
      dueOn: today.add(Duration(days: remaining)),
      state: switch (remaining) {
        > 0 => AssessmentDueState.upcoming,
        0 => AssessmentDueState.dueToday,
        _ => AssessmentDueState.overdue,
      },
      days: remaining.abs(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AssessmentCadence && other.validDays == validDays;

  @override
  int get hashCode => validDays.hashCode;
}

/// The calendar day [when] falls on, as a UTC midnight anchor.
///
/// Local date, UTC anchor. The date an owner sees is their own, so the
/// conversion happens first; the anchor is UTC so that adding days cannot be
/// bent by a daylight-saving transition — a 23-hour day would otherwise make
/// a difference of "one day" arrive an hour short.
DateTime _dayOf(DateTime when) {
  final local = when.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}

/// Whole days from [from] to [to], both being day anchors.
int _daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;
