import '../data/address_repository.dart';
import '../providers/address_provider.dart';

/// How the app's account-backed providers are actually built.
///
/// This exists so the wiring can be *asserted on*. Every provider here has a
/// working default that is deliberately the wrong choice for production —
/// [AddressProvider] with no repository falls back to device-local storage,
/// which is the behaviour that lost people's saved addresses when they signed
/// out. Building it correctly is therefore a decision, and a decision made
/// inside `main()` is one no test can see: the address suite passed in full
/// while `main.dart` built a local-only provider, because each test
/// constructed its own Firestore-backed one.
///
/// Pulling the choice out of `main()` and into a named function is the whole
/// change. `main()` calls this; a test calls this; there is one answer.
class AppComposition {
  const AppComposition._();

  /// The delivery-address provider the running app uses.
  ///
  /// Firestore-backed, with the device copy demoted to an offline cache — the
  /// address belongs to the account, not to the handset.
  static AddressProvider addressProvider() =>
      AddressProvider(repository: FirestoreAddressRepository());
}
