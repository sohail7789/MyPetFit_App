import 'auth_service.dart';
import 'photo_uploader.dart';
import 'firestore_service.dart';

/// The steps of deleting an account, in one place.
///
/// A thin composition of [FirestoreService] and [AuthService] rather than new
/// behaviour — the deletion logic lives in those services, and this exists so
/// the screen driving them can be tested without Firebase. Every method is
/// overridable for that reason; nothing here is a second implementation of
/// anything.
///
/// **Order is the whole point.** The user's documents are scoped to their uid
/// by the security rules, so the Firebase account has to outlive them: delete
/// the account first and its data becomes unreachable by any session, which
/// is not deletion, it is abandonment.
class AccountDeletion {
  const AccountDeletion({
    FirestoreService? firestore,
    PhotoUploader? photos,
  })  : _firestore = firestore,
        _photos = photos;

  final FirestoreService? _firestore;
  final PhotoUploader? _photos;

  FirestoreService get _documents => _firestore ?? FirestoreService();

  PhotoUploader get _storage => _photos ?? PhotoUploader();

  /// Which provider the session was established with, so a stale session is
  /// refreshed the way the account was actually created.
  String? get providerId => AuthService.instance.currentProviderId;

  /// Removes every document *and every stored file* the account owns.
  ///
  /// Storage first. The photo objects are addressed by the pet ids held in
  /// Firestore, so enumerating them has to happen while those documents still
  /// exist — delete the documents first and the objects become unreachable,
  /// which is how a deleted account came to leave its owner's and pets'
  /// photographs on the bucket indefinitely. Their paths are deterministic
  /// (`users/{uid}/profile/profile.jpg`,
  /// `users/{uid}/pets/{petId}/profile.jpg`), so nothing has to be listed and
  /// no Storage rule has to be relaxed to enumerate a prefix.
  ///
  /// Every delete is UID-scoped, tolerant of an object that was never created,
  /// and safe to run twice — a retry after a partial failure must not throw on
  /// the half that already succeeded.
  ///
  /// **This is client-side erasure, not a trusted server-side guarantee.** It
  /// runs on the user's device with the user's own credentials, so it can be
  /// interrupted — by loss of connection, or by the process being killed
  /// between the Storage deletes and the document deletes — and nothing
  /// afterwards reconciles what was missed. A Cloud Function on
  /// `auth.user().onDelete()` is what would make erasure guaranteed rather
  /// than best-effort.
  ///
  /// That function is specified in `docs/ACCOUNT_DELETION.md` — including
  /// what it must delete, why a document delete does not cascade to
  /// subcollections, and the billing change it requires — but deliberately
  /// not created here: it needs deployment and a Blaze plan, and inventing
  /// infrastructure in a repository that nobody has agreed to run is how a
  /// project acquires a function that everyone assumes is live.
  Future<void> deleteUserData() async {
    // Read the pet ids before anything is deleted.
    final petIds = <String>[];
    try {
      petIds.addAll((await _documents.getPets()).map((pet) => pet.id));
    } catch (_) {
      // An unreadable pet list must not block deleting everything else. The
      // owner photo and the documents are still removed below.
    }

    await _storage.deleteOwnerPhoto();
    for (final petId in petIds) {
      await _storage.deletePetPhoto(petId);
    }

    await _documents.deleteAllUserData();
  }

  /// Removes the Firebase Authentication account.
  ///
  /// Throws [ReauthenticationRequired] when the session is too old.
  Future<void> deleteAccount() => AuthService.instance.deleteAccount();

  Future<void> reauthenticateWithPassword(String password) =>
      AuthService.instance.reauthenticateWithPassword(password);

  Future<void> reauthenticateWithGoogle() =>
      AuthService.instance.reauthenticateWithGoogle();

  Future<void> reauthenticateWithApple() =>
      AuthService.instance.reauthenticateWithApple();
}
