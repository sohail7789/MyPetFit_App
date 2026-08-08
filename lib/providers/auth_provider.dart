import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _key = 'auth_state';

  /// Ends the Firebase and Google sessions.
  ///
  /// Injected only by tests, and resolved lazily at call time: reaching for
  /// [AuthService.instance] eagerly would touch `FirebaseAuth.instance` in
  /// every widget test that merely constructs a provider.
  final Future<void> Function()? _endSession;

  AuthProvider({@visibleForTesting Future<void> Function()? endSession})
      : _endSession = endSession;

  bool _isSignedIn = false;
  bool _isLoaded = false;
  String _username = '';
  String _email = '';
  String _firstName = '';
  String _lastName = '';

  bool get isSignedIn => _isSignedIn;

  /// True once the persisted session has been read from disk. The router
  /// waits for this before applying auth-gate redirects.
  bool get isLoaded => _isLoaded;
  String get username => _username;
  String get email => _email;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get displayName {
    final full = '$_firstName $_lastName'.trim();
    return full.isNotEmpty ? full : _username;
  }

  /// A stable id used to scope per-user persisted state (cart, pets, consent).
  String get userId => _email.isNotEmpty ? _email : _username;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _isSignedIn = json['isSignedIn'] as bool? ?? false;
        _username = json['username'] as String? ?? '';
        _email = json['email'] as String? ?? '';
        _firstName = json['firstName'] as String? ?? '';
        _lastName = json['lastName'] as String? ?? '';
      } catch (_) {
        // Corrupt payload — ignore and stay signed out.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> signIn(
    String email,
    String password,
  ) async {
    final credential = await AuthService.instance.signIn(
      email: email,
      password: password,
    );

    final user = credential.user!;

    _isSignedIn = true;
    _email = user.email ?? '';
    _username = user.displayName ?? '';
    _firstName = '';
    _lastName = '';

    await _persist();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(
      String email,
      ) async {
    await AuthService.instance.sendPasswordResetEmail(email);
  }


  Future<void> signInWithGoogle() async {
    final credential = await AuthService.instance.signInWithGoogle();

    final user = credential.user!;

    _isSignedIn = true;
    _email = user.email ?? '';

    final parts = (user.displayName ?? '').trim().split(' ');

    _firstName = parts.isNotEmpty ? parts.first : '';
    _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _username = user.email?.split('@').first ?? '';

    await _persist();
    notifyListeners();
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final credential = await AuthService.instance.signUp(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      password: password,
    );

    final user = credential.user!;

    _isSignedIn = true;
    _username = username.trim();
    _email = user.email ?? '';
    _firstName = firstName.trim();
    _lastName = lastName.trim();

    await _persist();

    notifyListeners();
  }


  /// Ends the session everywhere, not just on this screen.
  ///
  /// The fields below are what the UI reads; the *Firebase* session is what
  /// grants Firestore access. Clearing only the former left
  /// `FirebaseAuth.currentUser` signed in after a logout, so
  /// [FirestoreService] — which derives every path from that uid — could
  /// still read and write the previous account's records. On a shared device
  /// that is one person's health data reachable from another's session.
  ///
  /// The session is ended **first**, and a failure propagates without
  /// clearing the local fields: an app that says "signed out" while the
  /// session is alive is worse than one that reports it could not sign out.
  Future<void> signOut() async {
    await (_endSession ?? AuthService.instance.signOut)();

    _isSignedIn = false;
    _username = '';
    _email = '';
    _firstName = '';
    _lastName = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'isSignedIn': _isSignedIn,
        'username': _username,
        'email': _email,
        'firstName': _firstName,
        'lastName': _lastName,
      }),
    );
  }
}

/// Shared validators reused by sign-in / sign-up screens.
class AuthValidators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? username(String? v) {
    final base = required(v, field: 'Username');
    if (base != null) return base;
    if (v!.trim().length < 3) return 'At least 3 characters';
    return null;
  }

  static String? email(String? v) {
    final base = required(v, field: 'Email');
    if (base != null) return base;
    if (!_emailRegex.hasMatch(v!.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    final base = required(v, field: 'Password');
    if (base != null) return base;
    if (v!.length < 6) return 'At least 6 characters';
    return null;
  }
}
