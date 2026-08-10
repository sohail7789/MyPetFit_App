import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Why a pick did not produce a usable photo.
enum PhotoFailure {
  /// The sheet was dismissed, or the picker returned nothing. Not an error —
  /// callers should stay silent.
  cancelled,

  /// The file's extension is not one we accept.
  unsupportedFormat,

  /// The picker or the copy threw.
  failed,
}

/// The outcome of [PhotoStore.pick]: a saved path, or why there isn't one.
class PhotoResult {
  final String? path;
  final PhotoFailure? failure;

  const PhotoResult.saved(this.path) : failure = null;
  const PhotoResult.problem(this.failure) : path = null;

  bool get isSaved => path != null;
}

/// Picks profile photos and keeps a local copy of them.
///
/// **This is the cache layer, not the store of record.** The picker hands back
/// a file in a directory the OS is free to purge, so the image is copied into
/// the app's documents directory and read from there while it is still
/// current. Where it *lives* is Firebase Storage: [PhotoUploader] uploads the
/// file this class saved, and the resulting download URL is what Firestore
/// holds and what the app renders from.
///
/// That split matters, and this class used to be the whole of it. The absolute
/// path returned by [pick] was written into Firestore as though it were a
/// durable reference; on iOS the container segment of that path is reassigned
/// on reinstall and on every TestFlight update, so the stored path stopped
/// resolving and the photo appeared to have been deleted. Nothing here should
/// ever be persisted as a cloud reference again.
class PhotoStore {
  PhotoStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Formats we're willing to store.
  ///
  /// JPEG and PNG are the ask. HEIC/HEIF are here because that is what an
  /// iPhone camera roll actually returns, and rejecting it would fail for
  /// most iOS users on their own photos. WebP is common on Android.
  /// Everything else — GIF, BMP, TIFF, SVG — is refused rather than stored
  /// as something that may not decode.
  static const allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.heif',
    '.webp',
  };

  /// Longest edge, in pixels. A profile photo is shown at 96px at most, so
  /// anything larger is bytes on disk nobody sees. The picker downscales
  /// before the file is copied, so the saved file is the small one.
  static const _maxDimension = 1080.0;

  /// Re-encode quality for the downscale.
  static const _quality = 85;

  /// Prompts for a photo from [source] and returns where it was saved.
  ///
  /// [slot] namespaces the file — `pet-<id>`, `owner` — so replacing a photo
  /// overwrites rather than accumulating.
  Future<PhotoResult> pick({
    required ImageSource source,
    required String slot,
  }) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Photo pick failed: $error');
        debugPrintStack(stackTrace: stack);
      }
      return const PhotoResult.problem(PhotoFailure.failed);
    }

    if (picked == null) {
      return const PhotoResult.problem(PhotoFailure.cancelled);
    }

    final extension = _extensionOf(picked.name.isNotEmpty ? picked.name : picked.path);
    if (!allowedExtensions.contains(extension)) {
      return const PhotoResult.problem(PhotoFailure.unsupportedFormat);
    }

    try {
      return PhotoResult.saved(await _persist(picked, slot, extension));
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Photo save failed: $error');
        debugPrintStack(stackTrace: stack);
      }
      return const PhotoResult.problem(PhotoFailure.failed);
    }
  }

  /// Copies [picked] into the documents directory under a name derived from
  /// [slot], replacing whatever was there.
  Future<String> _persist(XFile picked, String slot, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final photos = Directory('${directory.path}/photos');
    if (!photos.existsSync()) {
      photos.createSync(recursive: true);
    }

    // A stable name per slot would be cached by Image.file against the old
    // bytes, so the name carries a stamp and the previous file is removed.
    await deleteFor(slot);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final destination = File('${photos.path}/$slot-$stamp$extension');
    await destination.writeAsBytes(await picked.readAsBytes(), flush: true);
    return destination.path;
  }

  /// Deletes the file at [path]. Safe to call with null or a stale path.
  ///
  /// Preferred over [deleteFor] when the record already knows where its
  /// photo is: a photo chosen before its pet had an id is filed under a
  /// draft slot, so deleting by the record's slot would miss it.
  Future<void> deleteAt(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (error) {
      if (kDebugMode) debugPrint('Photo delete failed: $error');
    }
  }

  /// Removes any stored photo for [slot]. Safe to call when there is none.
  Future<void> deleteFor(String slot) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photos = Directory('${directory.path}/photos');
      if (!photos.existsSync()) return;
      for (final entity in photos.listSync()) {
        final name = entity.path.split('/').last;
        if (entity is File && name.startsWith('$slot-')) {
          entity.deleteSync();
        }
      }
    } catch (error) {
      // A leftover file is not worth failing a save over.
      if (kDebugMode) debugPrint('Photo cleanup failed: $error');
    }
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot).toLowerCase();
  }

  /// Human-readable list for the "unsupported format" message.
  static String get allowedLabel => 'JPG, PNG, HEIC or WebP';
}
