import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';
import 'package:mypetfit_app/services/photo_uploader.dart';

import 'support/fake_cloud.dart';

/// Records a photo somewhere it survives the handset.
///
/// Substitutes for Firebase Storage: it hands back a URL shaped like one and
/// remembers what it was given, which is enough to prove the client half —
/// that an upload happens, that the URL is what reaches Firestore, and that
/// the URL is what comes back after a session is torn down and restored.
///
/// It does not prove a real bucket accepted the bytes. That needs the running
/// app against the real project, and is called out as unverified.
class FakeUploader implements PhotoUploader {
  final List<String> uploaded = [];

  /// Storage paths this uploader was asked to delete, in order.
  final List<String> deleted = [];

  Object? failure;

  @override
  Future<void> deleteOwnerPhoto() async {
    deleted.add('users/u1/profile/profile.jpg');
  }

  @override
  Future<void> deletePetPhoto(String petId) async {
    deleted.add('users/u1/pets/$petId/profile.jpg');
  }

  @override
  Future<String> uploadOwnerPhoto(File file) =>
      _upload('users/u1/profile/profile.jpg');

  @override
  Future<String> uploadPetPhoto(String petId, File file) =>
      _upload('users/u1/pets/$petId/profile.jpg');

  Future<String> _upload(String path) async {
    if (failure != null) throw failure!;
    uploaded.add(path);
    return 'https://firebasestorage.googleapis.com/v0/b/test/o/'
        '${Uri.encodeComponent(path)}?alt=media&token=${uploaded.length}';
  }

  @override
  Future<void> deleteAt(String url) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Lets the queued cloud writes run. [queueSync] returns immediately by
  /// design, so the test has to give the drain a turn before asserting on
  /// what reached the cloud. Bounded, because a failing write stays queued
  /// for retry on purpose and would otherwise spin here forever.
  Future<void> settle(PetInfoProvider pets) async {
    for (var i = 0; i < 50 && pets.hasPendingSync; i++) {
      await pumpEventQueue();
    }
    await pumpEventQueue();
  }

  /// A real file on disk, standing in for a freshly picked photo.
  Future<String> pickedFile(String name) async {
    final dir = await Directory.systemTemp.createTemp('mypetfit_photo');
    final file = File('${dir.path}/$name.jpg');
    await file.writeAsBytes(List<int>.filled(16, 0));
    addTearDown(() => dir.deleteSync(recursive: true));
    return file.path;
  }

  PetInfo pet(String id, String name, String photo) => PetInfo(
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

  group('profile photos outlive the session', () {
    test('owner and pet photos are stored as URLs, not device paths',
        () async {
      final cloud = FakeCloud();
      final uploader = FakeUploader();
      final pets = PetInfoProvider(service: cloud, uploader: uploader);
      await pets.init();

      await pets.setOwnerInfo(
        OwnerInfo(
          name: 'Sohail Inamdar',
          contactNumber: '9011778874',
          email: 'a@b.com',
          photoPath: await pickedFile('owner'),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await pets.addPet(pet('p1', 'Ronny', await pickedFile('p1')));
      await pets.addPet(pet('p2', 'Don', await pickedFile('p2')));
      await settle(pets);

      // The upload actually happened, at the paths the deployed Storage
      // rules already secure.
      expect(uploader.uploaded, [
        'users/u1/profile/profile.jpg',
        'users/u1/pets/p1/profile.jpg',
        'users/u1/pets/p2/profile.jpg',
      ]);

      // And what reached the cloud is a URL. This is the assertion that fails
      // against the old implementation, which wrote
      // `/var/mobile/.../Documents/photos/owner-….jpg` into Firestore — a
      // string that stops resolving the moment the app container is
      // reassigned.
      expect(
        PhotoUploader.isRemote(cloud.owner?.ownerPhoto),
        isTrue,
        reason: 'owner photo reached Firestore as "${cloud.owner?.ownerPhoto}" '
            '— a device path is not a durable reference',
      );
      for (final stored in cloud.pets) {
        expect(
          PhotoUploader.isRemote(stored.photoPath),
          isTrue,
          reason: '${stored.name} photo reached Firestore as '
              '"${stored.photoPath}"',
        );
      }
    });

    test('they come back after the session is torn down and restored',
        () async {
      final cloud = FakeCloud();
      final uploader = FakeUploader();

      final first = PetInfoProvider(service: cloud, uploader: uploader);
      await first.init();
      await first.setOwnerInfo(
        OwnerInfo(
          name: 'Sohail Inamdar',
          contactNumber: '9011778874',
          email: 'a@b.com',
          photoPath: await pickedFile('owner'),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await first.addPet(pet('p1', 'Ronny', await pickedFile('p1')));
      await first.addPet(pet('p2', 'Don', await pickedFile('p2')));
      await settle(first);

      // Sign out: local state and the device's own store are cleared, exactly
      // as AccountScreen._logOut does.
      await first.reset();
      SharedPreferences.setMockInitialValues({});

      // Sign in again as the same account and restore from the cloud.
      final second = PetInfoProvider(service: cloud, uploader: uploader);
      await second.init();
      await second.loadOwnerFromFirestore();
      await second.loadPetsFromFirestore();

      expect(
        PhotoUploader.isRemote(second.ownerInfo?.photoPath),
        isTrue,
        reason: 'the owner photo did not survive logout/login',
      );

      for (final name in ['Ronny', 'Don']) {
        final restored = second.pets.firstWhere((p) => p.name == name);
        expect(
          PhotoUploader.isRemote(restored.photoPath),
          isTrue,
          reason: "$name's photo did not survive logout/login",
        );
      }
    });

    test('an already-uploaded photo is not re-uploaded on every save',
        () async {
      final cloud = FakeCloud();
      final uploader = FakeUploader();
      final pets = PetInfoProvider(service: cloud, uploader: uploader);
      await pets.init();

      await pets.addPet(pet('p1', 'Ronny', await pickedFile('p1')));
      await settle(pets);
      expect(uploader.uploaded, hasLength(1));

      // Saving again with the URL already in place must not re-upload.
      pets.updatePet(0, pets.pets.first.copyWith(name: 'Ronny B'));
      await settle(pets);

      expect(
        uploader.uploaded,
        hasLength(1),
        reason: 'the same image was uploaded twice for one unchanged photo',
      );
    });

    test('a failed upload leaves the stored photo alone', () async {
      final cloud = FakeCloud();
      final uploader = FakeUploader();
      final pets = PetInfoProvider(service: cloud, uploader: uploader);
      await pets.init();

      uploader.failure = Exception('network down');

      await pets.addPet(pet('p1', 'Ronny', await pickedFile('p1')));
      await settle(pets);

      // Nothing was written with a device path as a consolation prize. The
      // write stays queued; the record keeps whatever it had.
      final stored = cloud.pets.where((p) => p.id == 'p1');
      for (final p in stored) {
        expect(
          p.photoPath?.startsWith('/') ?? false,
          isFalse,
          reason: 'a device path was written to Firestore after a failed '
              'upload — that is the original bug',
        );
      }
    });
  });
}
