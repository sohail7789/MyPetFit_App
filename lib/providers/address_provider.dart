import 'package:flutter/foundation.dart';
import '../data/address_repository.dart';
import '../models/address.dart';

/// Holds the saved delivery address.
///
/// Storage is injected so swapping [LocalAddressRepository] for a Firestore
/// one later needs no change here or in any screen.
class AddressProvider extends ChangeNotifier {
  final AddressRepository _repository;

  AddressProvider({AddressRepository? repository})
      : _repository = repository ?? LocalAddressRepository();

  Address? _address;
  bool _isLoaded = false;

  Address? get address => _address;
  bool get hasAddress => _address != null;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    _address = await _repository.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(Address address) async {
    _address = address;
    notifyListeners();
    await _repository.save(address);
  }

  /// Wipes the saved address. Called on sign-out alongside the other
  /// per-user providers.
  Future<void> reset() async {
    _address = null;
    notifyListeners();
    await _repository.clear();
  }
}
