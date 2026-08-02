import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';

/// Where the delivery address lives.
///
/// The app stores it on the device today, but everything is heading to
/// Firestore. Keeping the read/write behind this interface means that move
/// is a new implementation plus one line in `main.dart`, rather than surgery
/// on the checkout and settings screens.
abstract class AddressRepository {
  Future<Address?> load();
  Future<void> save(Address address);
  Future<void> clear();
}

/// Device-local implementation, matching how pets, cart and consent are
/// already persisted.
class LocalAddressRepository implements AddressRepository {
  static const _key = 'delivery_address';

  @override
  Future<Address?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Address.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt payload — behave as if nothing was saved.
      return null;
    }
  }

  @override
  Future<void> save(Address address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(address.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
