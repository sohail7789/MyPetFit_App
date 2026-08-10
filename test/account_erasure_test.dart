import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/config/composition.dart';
import 'package:mypetfit_app/data/address_repository.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/services/account_deletion.dart';

import 'support/fake_cloud.dart';
import 'photo_persistence_test.dart' show FakeUploader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PetInfo pet(String id, String name, {String? photo}) => PetInfo(
        id: id,
        name: name,
        breed: 'Beagle',
        ageYears: 3,
        ageMonths: 0,
        gender: PetGender.male,
        weightKg: 12,
        heightCm: 38,
        photoPath: photo,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  group('deleting an account takes the stored files with it', () {
    test('the owner photo and every pet photo are deleted from Storage',
        () async {
      final cloud = FakeCloud(
        pets: [pet('p1', 'Ronny'), pet('p2', 'Don')],
      );
      final photos = FakeUploader();

      await AccountDeletion(firestore: cloud, photos: photos).deleteUserData();

      // Every object the app can create, by its deterministic path. This is
      // the assertion that fails against the old implementation, which
      // deleted documents only and left the account's photographs on the
      // bucket under a uid that no longer had a session.
      expect(photos.deleted, [
        'users/u1/profile/profile.jpg',
        'users/u1/pets/p1/profile.jpg',
        'users/u1/pets/p2/profile.jpg',
      ]);
    });

    test('the files go before the documents that name them', () async {
      // The pet ids live in Firestore. Delete the documents first and the
      // objects can no longer be addressed, which is abandonment rather than
      // erasure.
      final cloud = FakeCloud(pets: [pet('p1', 'Ronny')]);
      final photos = FakeUploader();

      await AccountDeletion(firestore: cloud, photos: photos).deleteUserData();

      expect(
        photos.deleted,
        contains('users/u1/pets/p1/profile.jpg'),
        reason: 'the pet photo was not reachable by the time it was deleted',
      );
      expect(cloud.pets, isEmpty, reason: 'documents should still be gone');
    });

    test('it is safe to run twice after a partial failure', () async {
      final cloud = FakeCloud(pets: [pet('p1', 'Ronny')]);
      final photos = FakeUploader();
      final deletion = AccountDeletion(firestore: cloud, photos: photos);

      await deletion.deleteUserData();
      // A retry finds no pets and no objects, and must not throw.
      await expectLater(deletion.deleteUserData(), completes);
    });
  });

  group('removing a pet takes its photo with it', () {
    test('a Storage-backed photo is deleted from Storage', () async {
      final cloud = FakeCloud();
      final photos = FakeUploader();
      final pets = PetInfoProvider(service: cloud, uploader: photos);
      await pets.init();

      await pets.addPet(
        pet('p1', 'Ronny',
            photo: 'https://firebasestorage.googleapis.com/v0/b/t/o/x?alt=media'),
      );
      pets.removePet(0);
      await pumpEventQueue();

      expect(
        photos.deleted,
        contains('users/u1/pets/p1/profile.jpg'),
        reason: 'the remote object was orphaned — PhotoStore.deleteAt treats '
            'a URL as a filename and silently does nothing',
      );
    });

    test('a legacy device path is not sent to Storage', () async {
      final cloud = FakeCloud();
      final photos = FakeUploader();
      final pets = PetInfoProvider(service: cloud, uploader: photos);
      await pets.init();

      await pets.addPet(pet('p1', 'Ronny', photo: '/var/mobile/old/photo.jpg'));
      pets.removePet(0);
      await pumpEventQueue();

      expect(
        photos.deleted,
        isEmpty,
        reason: 'a device path names no Storage object; deleting one would '
            'target something that never existed',
      );
    });
  });

  group('the production composition root', () {
    test('builds the address provider on Firestore, not on the device', () {
      // The seam this exists to guard. `AddressProvider()` with no repository
      // silently falls back to device-local storage — the behaviour that lost
      // saved addresses on logout — and every address test passed anyway,
      // because each one constructed its own Firestore-backed repository.
      // This asserts what the *running app* builds.
      expect(
        AppComposition.addressProvider().repository,
        isA<FirestoreAddressRepository>(),
        reason: 'production is wired to local-only address storage; a saved '
            'address will not survive signing out',
      );
    });
  });
}
