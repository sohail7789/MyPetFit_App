import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firestore_service.dart' show NotSignedInException;

/// Puts profile photos somewhere they outlive the handset.
///
/// **The bug this exists to fix.** Photos were copied into the app's documents
/// directory and the resulting *absolute path* was stored — in
/// SharedPreferences, and then in Firestore, as though it were a durable
/// reference. It is not. On iOS the container segment of that path
/// (`…/Application/<UUID>/…`) is reassigned on reinstall and on every
/// TestFlight update, so the stored path stops resolving; `Image.file` fails,
/// the placeholder quietly takes over, and the photo appears to have been
/// deleted. On a second device it never resolved at all.
///
/// `firebase_storage` was already a dependency and the Storage rules already
/// secured `users/{uid}/profile/…` and `users/{uid}/pets/{petId}/…` to their
/// owner. Only the client half was missing. This is that half; it uses those
/// existing paths rather than inventing new ones, so no rule changes are
/// needed.
class PhotoUploader {
  PhotoUploader({FirebaseStorage? storage, FirebaseAuth? auth})
      : _storage = storage,
        _auth = auth;

  final FirebaseStorage? _storage;
  final FirebaseAuth? _auth;

  // Resolved lazily for the same reason [FirestoreService] does it: `.instance`
  // throws when Firebase has not been initialised, which would make this
  // impossible to construct in a test.
  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  FirebaseAuth get _authentication => _auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _authentication.currentUser;
    if (user == null) throw const NotSignedInException();
    return user.uid;
  }

  /// Whether [value] is already a durable reference rather than a device path.
  ///
  /// Used by the rendering layer as well: an account saved before this existed
  /// still has a filesystem path in Firestore, and both have to render.
  static bool isRemote(String? value) =>
      value != null &&
      (value.startsWith('http://') || value.startsWith('https://'));

  /// Uploads the owner's photo and returns its download URL.
  ///
  /// A deterministic object name, so replacing a photo overwrites in place and
  /// an account accumulates one file rather than one per change. The download
  /// URL carries a fresh token each upload, so the new URL differs from the old
  /// and nothing serves a stale cached image.
  Future<String> uploadOwnerPhoto(File file) =>
      _upload(file, 'users/$_uid/profile/profile.jpg');

  /// Uploads [petId]'s photo and returns its download URL.
  ///
  /// Keyed on the pet's stable id — never its name or its position in the
  /// list, either of which would re-point one pet's photo at another the
  /// moment a pet was renamed or removed.
  Future<String> uploadPetPhoto(String petId, File file) =>
      _upload(file, 'users/$_uid/pets/$petId/profile.jpg');

  Future<String> _upload(File file, String path) async {
    final reference = _bucket.ref(path);

    // Content type is set explicitly. The Storage rules validate against
    // `request.resource.contentType` matching an image type, and a file
    // uploaded without one arrives as `application/octet-stream` and is
    // rejected by the rules that are already deployed.
    await reference.putFile(
      file,
      SettableMetadata(contentType: _contentTypeOf(file.path)),
    );

    return reference.getDownloadURL();
  }

  /// Removes the owner's photo object.
  ///
  /// By its deterministic path rather than by a stored URL, so it works even
  /// when the record has already gone — which is the account-deletion case.
  Future<void> deleteOwnerPhoto() => _deleteAtPath('users/$_uid/profile/profile.jpg');

  /// Removes [petId]'s photo object.
  Future<void> deletePetPhoto(String petId) =>
      _deleteAtPath('users/$_uid/pets/$petId/profile.jpg');

  /// Deletes by path, tolerating an object that was never there.
  ///
  /// Idempotent on purpose: account deletion may be retried after a partial
  /// failure, and a pet may never have had a photo at all. `object-not-found`
  /// is the expected outcome in both cases, not an error worth surfacing.
  Future<void> _deleteAtPath(String path) async {
    try {
      await _bucket.ref(path).delete();
    } catch (_) {
      // Already gone, or never existed. Both are the desired end state.
    }
  }

  /// Removes a previously uploaded object.
  ///
  /// Deliberately separate from [uploadOwnerPhoto] and [uploadPetPhoto], and
  /// deliberately never called before one of them has succeeded: deleting the
  /// old image first would mean a failed upload leaves the account with no
  /// photo at all, which is worse than briefly paying for two.
  ///
  /// A failure here is swallowed. An orphaned object costs a few kilobytes; a
  /// thrown error at this point would report a successful photo change as a
  /// failure.
  Future<void> deleteAt(String url) async {
    if (!isRemote(url)) return;
    try {
      await _bucket.refFromURL(url).delete();
    } catch (_) {
      // Already gone, or not ours to delete. Not worth failing the save over.
    }
  }

  static String _contentTypeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    // HEIC/HEIF are transcoded to JPEG by the picker's resize, and the
    // deployed rules accept jpeg/png/webp only.
    return 'image/jpeg';
  }
}
