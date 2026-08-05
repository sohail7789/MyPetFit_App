import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's appearance preference.
///
/// The design ships light and dark variants of every screen but no control to
/// pick between them, so [ThemeMode.system] is the default and matches the
/// design's intent.
///
/// Settings exposes all three states directly, so "follow the device" stays
/// reachable rather than being a state you can only leave.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _isLoaded = false;

  ThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = _decode(prefs.getString(_key));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> select(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(mode));
  }

  static ThemeMode _decode(String? stored) => switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
