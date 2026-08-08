import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase will not perform a destructive operation on a stale session.
///
/// Its own type rather than a string comparison at the call site: deleting an
/// account is the one place where "we could not do it *yet*" and "we could
/// not do it" must never be confused, because the first is recoverable by
/// asking the user to confirm who they are and the second is not.
class ReauthenticationRequired implements Exception {
  const ReauthenticationRequired();

  @override
  String toString() =>
      'Please confirm who you are before deleting your account.';
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current signed-in user.
  User? get currentUser => _auth.currentUser;

  /// Listen to login/logout changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Create a new account and initialise the user's Firestore document.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName('$firstName $lastName');

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'username': username.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'name': '$firstName $lastName',
        'email': email.trim(),
        'photoUrl': user.photoURL ?? '',
        'phone': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  /// Email & password sign in.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw Exception('Incorrect email or password.');

        case 'user-not-found':
          throw Exception('No account found with this email.');

        case 'wrong-password':
          throw Exception('Incorrect email or password.');

        case 'invalid-email':
          throw Exception('Please enter a valid email address.');

        case 'too-many-requests':
          throw Exception(
            'Too many failed attempts. Please try again later.',
          );

        default:
          throw Exception(e.message ?? 'Login failed.');
      }
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user!;

      final userRef = _firestore.collection('users').doc(user.uid);

      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        final parts = (user.displayName ?? '').trim().split(' ');

        await userRef.set({
          'uid': user.uid,
          'username': user.email?.split('@').first ?? '',
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'phone': user.phoneNumber ?? '',
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        e.message ?? 'Google sign in failed.',
      );
    }
  }

  /// Logout.
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Forgot password.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');

        case 'invalid-email':
          throw Exception('Please enter a valid email address.');

        default:
          throw Exception(
            e.message ?? 'Failed to send reset email.',
          );
      }
    }
  }

  /// Which sign-in method the current session used.
  ///
  /// Re-authentication has to be performed with the provider the account was
  /// created under — asking a Google user for a password would be asking for
  /// something they never set.
  String? get currentProviderId {
    final providers = _auth.currentUser?.providerData;
    if (providers == null || providers.isEmpty) return null;
    return providers.first.providerId;
  }

  /// Proves the session is recent enough to delete the account with.
  ///
  /// Firebase refuses destructive operations on a stale session
  /// (`requires-recent-login`). The caller performs this only when asked to,
  /// because a fresh session needs no re-authentication and prompting anyway
  /// would be a password box for no reason.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in account.');

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('This account has no password to confirm.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('That password is not correct.');
        default:
          throw Exception(e.message ?? 'Could not confirm your password.');
      }
    }
  }

  /// Re-runs the Google sign-in so the session is fresh enough to delete.
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in account.');

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;

    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );
  }

  /// Deletes the Firebase Authentication account itself.
  ///
  /// Call **after** the user's Firestore data is gone: the security rules
  /// scope every document to the signed-in uid, so deleting the account
  /// first would strand that data with no session able to reach it.
  ///
  /// Throws [ReauthenticationRequired] when Firebase judges the session too
  /// old, which is the one failure the caller is expected to recover from
  /// rather than report.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in account.');

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const ReauthenticationRequired();
      }
      throw Exception(e.message ?? 'Could not delete the account.');
    }
  }

  /// Check whether an email is registered.
  Future<bool> isEmailRegistered(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}