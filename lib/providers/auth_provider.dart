import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _key = 'auth_state';

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

  Future<void> signIn(String username, String password) async {
    _username = username.trim();
    _isSignedIn = true;
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
    _username = username.trim();
    _email = email.trim();
    _firstName = firstName.trim();
    _lastName = lastName.trim();
    _isSignedIn = true;
    await _persist();
    notifyListeners();
  }

  Future<void> signOut() async {
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
