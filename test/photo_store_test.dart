import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/services/photo_store.dart';

/// Returns a fixed file, as if the user had picked it.
class _StubPicker extends ImagePickerPlatform {
  _StubPicker(this.path);

  final String? path;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      path == null ? null : XFile(path!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('accepted formats', () {
    test('covers what the ask named and what the cameras actually produce',
        () {
      // JPG and PNG were the requirement.
      expect(PhotoStore.allowedExtensions, containsAll({'.jpg', '.jpeg', '.png'}));
      // An iPhone camera roll hands back HEIC; refusing it would reject most
      // iOS users' own photos.
      expect(PhotoStore.allowedExtensions, contains('.heic'));
    });

    test('refuses formats that may not decode', () {
      for (final extension in ['.gif', '.bmp', '.tiff', '.svg', '.pdf']) {
        expect(
          PhotoStore.allowedExtensions,
          isNot(contains(extension)),
          reason: extension,
        );
      }
    });
  });

  group('picking', () {
    test('a dismissed picker is reported as cancelled, not as a failure',
        () async {
      ImagePickerPlatform.instance = _StubPicker(null);
      final result = await PhotoStore().pick(
        source: ImageSource.gallery,
        slot: 'pet-1',
      );

      expect(result.isSaved, isFalse);
      expect(result.failure, PhotoFailure.cancelled);
    });

    test('an unsupported file is rejected before anything is written',
        () async {
      ImagePickerPlatform.instance = _StubPicker('/tmp/animation.gif');
      final result = await PhotoStore().pick(
        source: ImageSource.gallery,
        slot: 'pet-1',
      );

      expect(result.failure, PhotoFailure.unsupportedFormat);
    });

    test('the extension check ignores case', () async {
      // A .JPG from a DSLR import is the same file as a .jpg.
      ImagePickerPlatform.instance = _StubPicker('/tmp/DSC_0001.JPG');
      final result = await PhotoStore().pick(
        source: ImageSource.gallery,
        slot: 'pet-1',
      );

      // It gets past the format gate; the copy then fails in a test
      // environment with no documents directory, which is a different
      // failure from the one being asserted against.
      expect(result.failure, isNot(PhotoFailure.unsupportedFormat));
    });
  });

  group('clearing a photo', () {
    test('PetInfo.copyWith can remove one', () {
      const pet = PetInfo(
        id: 'p1',
        name: 'Bruno',
        breed: 'Indie',
        ageYears: 3,
        ageMonths: 0,
        gender: PetGender.male,
        species: PetSpecies.dog,
        weightKg: 12,
        heightCm: 40,
        photoPath: '/photos/pet-p1-1.jpg',
      );

      // Omitting it keeps the photo — that is what every other field does.
      expect(pet.copyWith(name: 'Rex').photoPath, isNotNull);
      // Only the explicit flag drops it.
      expect(pet.copyWith(clearPhoto: true).photoPath, isNull);
    });

    test('OwnerInfo.copyWith can remove one', () {
      const owner = OwnerInfo(
        name: 'Priya',
        contactNumber: '9000000000',
        email: 'p@example.com',
        photoPath: '/photos/owner-1.jpg',
      );

      expect(owner.copyWith(name: 'Priya S').photoPath, isNotNull);
      expect(owner.copyWith(clearPhoto: true).photoPath, isNull);
    });

    test('the photo survives a round trip through JSON', () {
      const owner = OwnerInfo(
        name: 'Priya',
        contactNumber: '9000000000',
        email: 'p@example.com',
        photoPath: '/photos/owner-1.jpg',
      );

      expect(
        OwnerInfo.fromJson(owner.toJson()).photoPath,
        '/photos/owner-1.jpg',
      );
    });
  });
}
