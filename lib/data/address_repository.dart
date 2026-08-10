import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';
import '../services/firestore_service.dart';

/// Where the delivery addresses live.
///
/// Keeping the read/write behind this interface is what made moving them off
/// the device a new implementation plus one line in `main.dart`, rather than
/// surgery on the checkout and settings screens.
abstract class AddressRepository {
  Future<AddressBook> load();
  Future<void> save(AddressBook book);

  /// Forgets whatever is cached **on this device**.
  ///
  /// Called on sign-out, and deliberately not a delete of the account's own
  /// record: the next person to use the handset must not inherit someone's
  /// home address, and the person signing out must not lose it. Anything
  /// that genuinely erases the account's data goes through
  /// [FirestoreService.deleteAllUserData].
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
      final book = AddressBook(addresses: [address], defaultId: address.id);
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

/// Account-backed storage, with the device copy kept as a cache.
///
/// **The address used to live only on the handset, and sign-out deleted it.**
/// That is why an address entered, saved and shown on screen was gone after a
/// relaunch that passed through a sign-in: nothing had ever recorded it
/// against the account, so there was nothing to come back to. Storing it in
/// `users/{uid}` makes it the account's, which is what an address delivered
/// to actually is.
///
/// The local copy is still written, and is what a cold offline launch reads.
/// It is a cache of the account's record, never the record itself.
class FirestoreAddressRepository implements AddressRepository {
  final FirestoreService _firestore;
  final AddressRepository _cache;

  FirestoreAddressRepository({
    FirestoreService? service,
    AddressRepository? cache,
  }) : _firestore = service ?? FirestoreService(),
       _cache = cache ?? LocalAddressRepository();

  /// Reads the account's book, falling back to the device cache.
  ///
  /// The fallback covers being offline and being called before the session
  /// is up. A failed read must never look like an empty address book — that
  /// would replace a saved address with an invitation to add one, and the
  /// save that followed would write the emptiness back.
  @override
  Future<AddressBook> load() async {
    try {
      final remote = await _firestore.getAddressBook();
      if (remote != null) {
        // Refresh the cache so the next cold start has it even offline.
        await _cache.save(remote);
        return remote;
      }
      // The account has no book yet. A device that already holds one is a
      // pre-Firestore install: hand it up so the next save promotes it.
      return _cache.load();
    } on NotSignedInException {
      return _cache.load();
    } catch (_) {
      // Offline or a transient Firestore failure. The cache is the best
      // available answer, and is not written back over.
      return _cache.load();
    }
  }

  /// Writes the device cache first, then the account.
  ///
  /// In that order on purpose: the cache write cannot fail for a reason the
  /// user could act on, so doing it first means an address entered offline
  /// survives the trip home even though the Firestore write is about to
  /// throw. The throw still propagates — a save that did not reach the
  /// account is not reported as one that did.
  @override
  Future<void> save(AddressBook book) async {
    await _cache.save(book);
    await _firestore.saveAddressBook(book);
  }

  /// Clears the device cache only. See [AddressRepository.clear].
  @override
  Future<void> clear() => _cache.clear();
}
