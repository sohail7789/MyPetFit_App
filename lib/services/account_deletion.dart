import 'auth_service.dart';
import 'firestore_service.dart';

/// The steps of deleting an account, in one place.
///
/// A thin composition of [FirestoreService] and [AuthService] rather than new
/// behaviour — the deletion logic lives in those services, and this exists so
/// the screen driving them can be tested without Firebase. Every method is
/// overridable for that reason; nothing here is a second implementation of
/// anything.
///
/// **Order is the whole point.** The user's documents are scoped to their uid
/// by the security rules, so the Firebase account has to outlive them: delete
/// the account first and its data becomes unreachable by any session, which
/// is not deletion, it is abandonment.
class AccountDeletion {
  const AccountDeletion();

  /// Which provider the session was established with, so a stale session is
  /// refreshed the way the account was actually created.
  String? get providerId => AuthService.instance.currentProviderId;

  /// Removes every document the account owns.
  Future<void> deleteUserData() => FirestoreService().deleteAllUserData();

  /// Removes the Firebase Authentication account.
  ///
  /// Throws [ReauthenticationRequired] when the session is too old.
  Future<void> deleteAccount() => AuthService.instance.deleteAccount();

  Future<void> reauthenticateWithPassword(String password) =>
      AuthService.instance.reauthenticateWithPassword(password);

  Future<void> reauthenticateWithGoogle() =>
      AuthService.instance.reauthenticateWithGoogle();
}
