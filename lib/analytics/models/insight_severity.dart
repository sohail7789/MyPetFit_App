/// How much attention a finding deserves.
///
/// Decided in the domain, never by whatever is rendering: a notification, a
/// dashboard highlight, an email digest and a veterinarian's queue all need
/// to prioritise the same findings the same way, and they cannot if each
/// works it out from the wording.
///
/// Deliberately not clinical language. These describe how loudly the app
/// should speak, not how ill an animal is — the assessment is a screening
/// aid, and a severity here is never a diagnosis.
enum InsightSeverity {
  /// Something got better.
  positive,

  /// Nothing moved, or the finding is context rather than change.
  neutral,

  /// A decline worth reading.
  caution,

  /// A decline large enough to lead with.
  alert,
}
