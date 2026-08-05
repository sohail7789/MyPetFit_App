import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/theme.dart';
import '../services/photo_store.dart';
import 'paw_mark.dart';

/// The circular photo well used for pets and owners.
///
/// Shows the stored image when there is one and the design's paw placeholder
/// when there isn't. Tapping opens a sheet offering the camera, the gallery,
/// and — once a photo exists — a way to remove it.
class PhotoSlot extends StatelessWidget {
  /// Where the current photo lives, or null for the empty state.
  final String? photoPath;

  /// Namespaces the saved file. See [PhotoStore.pick].
  final String slot;

  /// Called with the new path, or null when the photo is removed.
  final ValueChanged<String?> onChanged;

  final double size;

  const PhotoSlot({
    super.key,
    required this.photoPath,
    required this.slot,
    required this.onChanged,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final file = photoPath == null ? null : File(photoPath!);
    // A path can outlive its file — the photo directory is inside the app
    // sandbox, which a reinstall or a "clear storage" wipes while the saved
    // record survives. Falling back to the placeholder beats a broken box.
    final hasPhoto = file != null && file.existsSync();

    return Semantics(
      button: true,
      label: hasPhoto ? 'Change photo' : 'Add a photo',
      child: GestureDetector(
        onTap: () => _open(context, hasPhoto: hasPhoto),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipOval(
                  child: hasPhoto
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          // Keyed on the path so replacing the photo shows
                          // the new bytes instead of the cached old ones.
                          key: ValueKey(photoPath),
                          errorBuilder: (context, _, _) =>
                              _Placeholder(size: size),
                        )
                      : _Placeholder(size: size),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: context.c.action,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.c.surface, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: context.c.shadowTone.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasPhoto
                        ? Icons.edit_outlined
                        : Icons.photo_camera_outlined,
                    size: 14,
                    color: context.c.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, {required bool hasPhoto}) async {
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: sheetContext.c.dotInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            _SheetRow(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PhotoAction.camera),
            ),
            _SheetRow(
              icon: Icons.photo_library_outlined,
              label: 'Choose from library',
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PhotoAction.gallery),
            ),
            if (hasPhoto)
              _SheetRow(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                destructive: true,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == _PhotoAction.remove) {
      await PhotoStore().deleteFor(slot);
      onChanged(null);
      return;
    }

    final result = await PhotoStore().pick(
      source: choice == _PhotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      slot: slot,
    );

    if (result.isSaved) {
      onChanged(result.path);
      return;
    }

    // A dismissed picker is not a failure worth interrupting anyone over.
    if (result.failure == PhotoFailure.cancelled || !context.mounted) return;

    final message = result.failure == PhotoFailure.unsupportedFormat
        ? 'That file type isn\'t supported. Use ${PhotoStore.allowedLabel}.'
        : "Couldn't open that photo. Try another one.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.font(color: context.c.onAccent)),
        backgroundColor: context.c.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Read-only circular avatar for lists and headers.
///
/// Shares [PhotoSlot]'s missing-file handling so a photo whose file has been
/// wiped degrades to the paw rather than a broken image, wherever it appears.
class PhotoAvatar extends StatelessWidget {
  final String? photoPath;
  final double size;

  const PhotoAvatar({super.key, required this.photoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    final file = photoPath == null ? null : File(photoPath!);
    final hasPhoto = file != null && file.existsSync();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: hasPhoto
            ? Image.file(
                file,
                fit: BoxFit.cover,
                key: ValueKey(photoPath),
                errorBuilder: (context, _, _) => _Placeholder(size: size),
              )
            : _Placeholder(size: size),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

class _Placeholder extends StatelessWidget {
  final double size;

  const _Placeholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.c.tint.withValues(alpha: 0.7),
      ),
      child: Center(
        child: PawMark(
          size: size * 0.4,
          color: context.c.actionText,
          opacity: 0.3,
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colour =
        destructive ? context.c.dangerText : context.c.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colour),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTheme.font(
                size: 15,
                weight: FontWeight.w700,
                color: colour,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
