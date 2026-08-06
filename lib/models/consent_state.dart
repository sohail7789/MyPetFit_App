import '../services/sync_reconciler.dart' show kUnknownUpdatedAt;
import 'owner_profile.dart' show parseUpdatedAt;
import 'pet_info.dart' show ConsentRecord;

/// Consent as Firestore stores it, on the user document under `consent`.
///
/// Consent belongs to the account, not the handset. It used to live only in
/// SharedPreferences, which meant signing out — or signing in on a second
/// device — lost it, and the router's first gate walked a returning user back
/// through a form they had already signed.
///
/// Kept beside the owner profile rather than inside it because the two are
/// filled in at different times: consent is given on screen 10, the owner
/// record on screen 11. Folding consent into [OwnerProfile] would write a
/// half-formed owner document that `getOwnerProfile` would then reject.
class ConsentState {
  final bool given;

  /// Who signed and when, where a signature was captured. Absent for consent
  /// recorded without one.
  final ConsentRecord? record;

  /// When consent last changed, in UTC. Stamped by the provider so the same
  /// newest-wins reconciliation as every other record applies.
  final DateTime updatedAt;

  const ConsentState({
    required this.given,
    this.record,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'given': given,
        if (record != null) 'record': record!.toJson(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ConsentState.fromMap(Map<String, dynamic> map) {
    final record = map['record'];

    return ConsentState(
      given: map['given'] as bool? ?? false,
      record: record is Map
          ? ConsentRecord.fromJson(Map<String, dynamic>.from(record))
          : null,
      // A document written before consent was synced decodes to the epoch, so
      // the first reconcile resolves in favour of whichever side has a real
      // decision on file.
      updatedAt: parseUpdatedAt(map['updatedAt']),
    );
  }

  /// True when both sides record the same decision. Used to tell a genuine
  /// conflict from two copies of the same signature.
  bool sameContentAs(ConsentState other) =>
      given == other.given &&
      record?.signatureName == other.record?.signatureName &&
      record?.signedAt == other.record?.signedAt;

  /// True when this carries no real timestamp — see [kUnknownUpdatedAt].
  bool get isUndated => updatedAt == kUnknownUpdatedAt;
}
