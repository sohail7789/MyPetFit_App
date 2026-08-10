import 'package:flutter/foundation.dart';
import '../data/address_repository.dart';
import '../models/address.dart';

/// Holds the saved delivery addresses and which one is the default.
///
/// Storage is injected so swapping [LocalAddressRepository] for a Firestore
/// one later needs no change here or in any screen.
class AddressProvider extends ChangeNotifier {
  final AddressRepository _repository;

  AddressProvider({AddressRepository? repository})
      : _repository = repository ?? LocalAddressRepository();

  /// Where this provider actually reads and writes.
  ///
  /// Exposed so the composition root can be asserted on. The default is
  /// device-local, which is the *old* behaviour and the reason the address
  /// vanished on logout — so "which repository did production wire up" is a
  /// release-blocking fact, not an implementation detail. Without a way to
  /// see it, every address test passed while `main.dart` built a local-only
  /// provider, because the tests constructed their own.
  @visibleForTesting
  AddressRepository get repository => _repository;

  AddressBook _book = const AddressBook();
  bool _isLoaded = false;

  List<Address> get addresses => List.unmodifiable(_book.addresses);
  String? get defaultId => _book.defaultId;

  /// The address deliveries go to, or null when none are saved.
  Address? get address => _book.defaultAddress;

  bool get hasAddress => _book.addresses.isNotEmpty;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    _book = await _repository.load();
    _isLoaded = true;
    notifyListeners();
  }

  Address? byId(String id) {
    for (final a in _book.addresses) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Adds [address], or replaces the entry with the same id.
  ///
  /// The first address saved always becomes the default — there is nothing
  /// else for it to be.
  Future<void> save(Address address, {bool makeDefault = false}) async {
    final list = [..._book.addresses];
    final at = list.indexWhere((a) => a.id == address.id);
    if (at >= 0) {
      list[at] = address;
    } else {
      list.add(address);
    }

    final shouldDefault = makeDefault || _book.addresses.isEmpty;
    await _write(
      AddressBook(
        addresses: list,
        defaultId: shouldDefault ? address.id : _book.defaultId,
      ),
    );
  }

  Future<void> remove(String id) async {
    final list = _book.addresses.where((a) => a.id != id).toList();
    // Removing the default hands the role to whatever is left, so checkout
    // never ends up pointing at nothing while addresses still exist.
    final nextDefault =
        _book.defaultId == id ? (list.isEmpty ? null : list.first.id) : _book.defaultId;
    await _write(AddressBook(addresses: list, defaultId: nextDefault));
  }

  Future<void> setDefault(String id) async {
    if (byId(id) == null || _book.defaultId == id) return;
    await _write(AddressBook(addresses: _book.addresses, defaultId: id));
  }

  /// Wipes every saved address. Called on sign-out alongside the other
  /// per-user providers.
  Future<void> reset() async {
    _book = const AddressBook();
    notifyListeners();
    await _repository.clear();
  }

  Future<void> _write(AddressBook book) async {
    _book = book;
    notifyListeners();
    await _repository.save(book);
  }
}
