import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';

/// Where the delivery addresses live.
///
/// The app stores them on the device today, but everything is heading to
/// Firestore. Keeping the read/write behind this interface means that move
/// is a new implementation plus one line in `main.dart`, rather than surgery
/// on the checkout and settings screens.
abstract class AddressRepository {
  Future<AddressBook> load();
  Future<void> save(AddressBook book);
  Future<void> clear();
}

/// Device-local implementation, matching how pets, cart and consent are
/// already persisted.
class LocalAddressRepository implements AddressRepository {
  static const _key = 'address_book';

  /// The key used while the app supported exactly one address. Read once on
  /// load and folded into the book, so upgrading does not silently lose the
  /// address someone already entered.
  static const _legacyKey = 'delivery_address';

  @override
  Future<AddressBook> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final list = (json['addresses'] as List? ?? [])
            .map((e) => Address.fromJson(e as Map<String, dynamic>))
            .toList();
        return AddressBook(
          addresses: list,
          defaultId: json['defaultId'] as String?,
        );
      } catch (_) {
        // Corrupt payload — behave as if nothing was saved.
        return const AddressBook();
      }
    }

    return _migrateLegacy(prefs);
  }

  /// Promotes a pre-multi-address save into a one-entry book and writes it
  /// back under the new key.
  Future<AddressBook> _migrateLegacy(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null) return const AddressBook();

    try {
      final address = Address.fromJson(
        jsonDecode(legacy) as Map<String, dynamic>,
        fallbackId: 'addr_legacy',
      );
      final book = AddressBook(
        addresses: [address],
        defaultId: address.id,
      );
      await save(book);
      await prefs.remove(_legacyKey);
      return book;
    } catch (_) {
      return const AddressBook();
    }
  }

  @override
  Future<void> save(AddressBook book) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'addresses': book.addresses.map((a) => a.toJson()).toList(),
        if (book.defaultId != null) 'defaultId': book.defaultId,
      }),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_legacyKey);
  }
}
