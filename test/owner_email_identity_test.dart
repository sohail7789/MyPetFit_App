import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypetfit_app/models/owner_profile.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/providers/pet_info_provider.dart';

import 'support/fake_cloud.dart';

/// The account owns the account's address. Nothing else writes it.
///
/// `users/{uid}.email` is written by [AuthService] straight from the Firebase
/// user at sign-up and on every social sign-in. The owner document used to
/// write it as well, from whatever the client was holding — which made the
/// account's own identity settable by a profile form. The value happened to
/// be right, because it came from the signed-in user, but "happens to be
/// right" is not the same property as "cannot be wrong", and a record that
/// the thing it describes can overwrite is not an authority on anything.
///
/// These fix the two halves of that: the owner document never writes an
/// address, and it still reads the one it is given — including the legacy key,
/// which is load-bearing rather than merely polite. Email/password *sign-in*
/// refreshes only `lastLogin`, so a document written before the move can hold
/// `ownerEmail` and no `email` indefinitely; without the fallback those owners
/// go blank on their profile and in their report PDF.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  OwnerProfile profile({String email = 'owner@example.com'}) => OwnerProfile(
        ownerName: 'Sohail Inamdar',
        ownerPhone: '+91 90000 11111',
        ownerEmail: email,
        vetName: 'Dr Rao',
        vetPhone: '+91 90000 00000',
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  group('the owner document', () {
    test('writes no email key of any kind', () {
      final map = profile().toMap();

      // Named explicitly rather than checked as a substring: the point is
      // that *this document* does not carry the account's address, under the
      // canonical key or the legacy one.
      expect(map.containsKey(OwnerProfile.emailField), isFalse);
      expect(map.containsKey(OwnerProfile.legacyEmailField), isFalse);

      // And nothing that merely looks like one slipped in under another name.
      expect(
        map.keys.where((k) => k.toLowerCase().contains('email')),
        isEmpty,
        reason: 'the account is the authority on its own address; a profile '
            'save must not be able to restate it',
      );
    });

    test('still writes everything it does own', () {
      expect(
        profile().toMap().keys.toSet(),
        {
          'ownerName',
          'ownerPhone',
          'ownerPhoto',
          'vetName',
          'vetPhone',
          'updatedAt',
        },
      );
    });
  });

  group('reading an owner document', () {
    test('prefers the canonical key', () {
      final decoded = OwnerProfile.fromMap({
        'ownerName': 'Sohail',
        OwnerProfile.emailField: 'account@example.com',
        OwnerProfile.legacyEmailField: 'stale@example.com',
      });

      expect(decoded.ownerEmail, 'account@example.com');
    });

    test('falls back to the legacy key for documents written before the move',
        () {
      final decoded = OwnerProfile.fromMap({
        'ownerName': 'Sohail',
        OwnerProfile.legacyEmailField: 'legacy@example.com',
      });

      expect(
        decoded.ownerEmail,
        'legacy@example.com',
        reason: 'email/password sign-in refreshes only lastLogin, so these '
            'documents can hold ownerEmail and no email forever',
      );
    });

    test('is empty rather than null when the document has neither', () {
      expect(OwnerProfile.fromMap({'ownerName': 'Sohail'}).ownerEmail, '');
    });
  });

  group('saving owner details', () {
    test('sends no email key to the cloud', () async {
      final cloud = FakeCloud();
      final pets = PetInfoProvider(service: cloud);

      await pets.setOwnerInfo(
        OwnerInfo(
          name: 'Sohail Inamdar',
          contactNumber: '+91 90000 11111',
          // Whatever the form carries, it must not reach the account's field.
          email: 'typed@example.com',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      // The write is queued rather than awaited, by design — let it drain.
      for (var i = 0; i < 20 && cloud.owner == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(cloud.owner, isNotNull, reason: 'the profile should have synced');
      expect(
        cloud.owner!.toMap().keys.where((k) => k.toLowerCase().contains('email')),
        isEmpty,
        reason: 'this is the exact payload that reaches users/{uid}; an email '
            'key here is the account being overwritten by the profile form',
      );
      // The rest of the profile still saves.
      expect(cloud.owner!.toMap()['ownerName'], 'Sohail Inamdar');
    });
  });
}
