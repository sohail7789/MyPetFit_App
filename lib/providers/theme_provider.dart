import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's appearance preference.
///
/// The design ships light and dark variants of every screen but no control to
/// pick between them, so [ThemeMode.system] is the default and matches the
/// design's intent.
///
/// Settings exposes this as a single toggle rather than a three-way choice.
/// That means "follow the device" is the state you start in and leave the
/// moment you touch the switch — there is no way back to it from the UI,
/// which is the accepted trade for a control that reads as on or off.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _isLoaded = false;

  ThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;

  /// True while the appearance still tracks the device rather than a choice
  /// made here. Drives the toggle's supporting line.
  bool get isFollowingSystem => _mode == ThemeMode.system;

  /// Pins the appearance from the settings toggle.
  ///
  /// Takes the resolved on/off the switch shows rather than a [ThemeMode],
  /// so flipping it while on `system` lands on the opposite of what is
  /// currently painted instead of silently doing nothing.
  Future<void> setDark(bool dark) =>
      select(dark ? ThemeMode.dark : ThemeMode.light);

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
