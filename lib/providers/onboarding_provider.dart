import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _key = 'onboarding_complete';
  bool _isComplete = false;
  bool _isLoaded = false;

  bool get isComplete => _isComplete;

  /// True once the persisted value has been read from disk. The router waits
  /// for this before making any redirect decisions so the user never sees a
  /// brief flash of the welcome screen when they've already onboarded.
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isComplete = prefs.getBool(_key) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    notifyListeners();
  }
}
