import '../services/sync_reconciler.dart' show kUnknownUpdatedAt;

/// The owner document as Firestore stores it.
class OwnerProfile {
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String? ownerPhoto;
  final String? vetName;
  final String? vetPhone;

  /// When this record was last edited, in UTC.
  ///
  /// Set by the provider on every mutation, never by the UI and never by
  /// Firestore's serverTimestamp: a server stamp resolves when the write
  /// lands, so an edit made offline would be dated by when the device
  /// reconnected rather than when it happened, and two devices would be
  /// ordered by who came back first.
  final DateTime updatedAt;

  const OwnerProfile({
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    this.ownerPhoto,
    this.vetName,
    this.vetPhone,
    required this.updatedAt,
  });

  /// The canonical Firestore key for the account address.
  ///
  /// `users/{uid}.email` is written at sign-up and on every social sign-in by
  /// [AuthService] straight from the Firebase user, so it already existed and
  /// was already right. This document then wrote a second, separately typed
  /// address under `ownerEmail`, and the two could disagree about the same
  /// person — the owner profile screen even had a row to show both when they
  /// did. One account, one address; this is that one.
  static const emailField = 'email';

  /// Where the address used to be written. Read for records created before
  /// [emailField] became canonical, never written again.
  static const legacyEmailField = 'ownerEmail';

  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      emailField: ownerEmail,
      'ownerPhoto': ownerPhoto,
      'vetName': vetName,
      'vetPhone': vetPhone,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory OwnerProfile.fromMap(Map<String, dynamic> map) {
    return OwnerProfile(
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      // Canonical first, then the legacy key. A document written before the
      // move keeps displaying the address it already has instead of going
      // blank, and nothing needs migrating for that to be true — the next
      // save rewrites it under the canonical key on its own.
      ownerEmail: map[emailField] ?? map[legacyEmailField] ?? '',
      ownerPhoto: map['ownerPhoto'],
      vetName: map['vetName'],
      vetPhone: map['vetPhone'],
      // Documents written before timestamps existed decode to the epoch, so
      // the first reconcile resolves in favour of the other side rather than
      // overwriting real data with an undated copy.
      updatedAt: parseUpdatedAt(map['updatedAt']),
    );
  }

  /// True when every field a user can edit matches. Used to tell a genuine
  /// conflict from two copies of the same edit.
  bool sameContentAs(OwnerProfile other) =>
      ownerName == other.ownerName &&
      ownerPhone == other.ownerPhone &&
      ownerEmail == other.ownerEmail &&
      ownerPhoto == other.ownerPhoto &&
      vetName == other.vetName &&
      vetPhone == other.vetPhone;
}

/// Decodes an `updatedAt` from storage, defaulting to [kUnknownUpdatedAt].
DateTime parseUpdatedAt(Object? raw) {
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc();
  }
  return kUnknownUpdatedAt;
}
