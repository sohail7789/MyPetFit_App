import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypetfit_app/data/address_repository.dart';
import 'package:mypetfit_app/models/address.dart';
import 'package:mypetfit_app/providers/address_provider.dart';

import 'support/fake_cloud.dart';

/// The delivery address is account state, not device state.
///
/// It used to be written only to SharedPreferences, and sign-out deleted it —
/// so an address entered, saved and shown on screen was gone after a relaunch
/// that passed through a sign-in, with nothing anywhere to restore it from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Address addressOf(String id, {String city = 'Pune'}) => Address(
    id: id,
    fullName: 'Sohail Inamdar',
    phone: '9011778874',
    line1: '12B, MG Road',
    city: city,
    state: 'Maharashtra',
    pincode: '411001',
  );

  group('a saved address belongs to the account', () {
    test('it survives a restart that clears the device', () async {
      final cloud = FakeCloud();

      final before = AddressProvider(
        repository: FirestoreAddressRepository(service: cloud),
      );
      await before.init();
      await before.save(addressOf('a1'));

      expect(
        cloud.addressBook,
        isNotNull,
        reason: 'the save must reach the account, not just the handset',
      );

      // A different handset, or the same one after sign-out cleared its
      // cache: nothing local, everything still on the account.
      SharedPreferences.setMockInitialValues({});

      final after = AddressProvider(
        repository: FirestoreAddressRepository(service: cloud),
      );
      await after.init();

      expect(after.hasAddress, isTrue);
      expect(after.address?.id, 'a1');
      expect(after.address?.line1, '12B, MG Road');
    });

    test('signing out clears the device but not the account', () async {
      final cloud = FakeCloud();
      final provider = AddressProvider(
        repository: FirestoreAddressRepository(service: cloud),
      );

      await provider.init();
      await provider.save(addressOf('a1'));
      await provider.reset();

      expect(
        provider.hasAddress,
        isFalse,
        reason: 'the next person on this handset must not inherit it',
      );
      expect(
        cloud.addressBook?.addresses,
        hasLength(1),
        reason: 'the person signing out must not lose it',
      );
    });

    test(
      'an edit updates in place rather than adding a second entry',
      () async {
        final cloud = FakeCloud();
        final provider = AddressProvider(
          repository: FirestoreAddressRepository(service: cloud),
        );

        await provider.init();
        await provider.save(addressOf('a1'));
        await provider.save(addressOf('a1', city: 'Mumbai'));

        expect(provider.addresses, hasLength(1));
        expect(provider.address?.city, 'Mumbai');
        expect(cloud.addressBook?.addresses, hasLength(1));
      },
    );

    test('an unreachable account falls back to the device copy', () async {
      final cloud = FakeCloud();
      final provider = AddressProvider(
        repository: FirestoreAddressRepository(service: cloud),
      );

      await provider.init();
      await provider.save(addressOf('a1'));

      // The connection drops. A failed read must not read as "no addresses"
      // — that would offer to add one over an address already on file.
      cloud.offline = Exception('unavailable');

      final offline = AddressProvider(
        repository: FirestoreAddressRepository(service: cloud),
      );
      await offline.init();

      expect(offline.hasAddress, isTrue);
      expect(offline.address?.id, 'a1');
    });
  });
}
