import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's reminder preferences.
///
/// Same shape as [ThemeProvider] and [LocaleProvider] — read once on
/// startup, written on change — because a preference screen that forgets
/// what it was told is the defect this replaces: the reminder toggles used
/// to be a `Map<String, bool>` in widget state, reset by popping the screen,
/// under a line that told the user they were saved.
///
/// One preference, because one reminder has data behind it. The assessment
/// cadence is computed from a date the app already stores. Vaccination and
/// deworming reminders would need dates [PetInfo] does not carry, and order
/// updates would need the ordering backend that is deliberately closed — so
/// those toggles are gone rather than persisted and inert.
class RemindersProvider extends ChangeNotifier {
  static const _key = 'reminders_assessment_retake';

  /// Off until asked for. A notification nobody opted into is the kind that
  /// gets an app's permission revoked for good.
  static const bool defaultAssessmentRetake = false;

  bool _assessmentRetake = defaultAssessmentRetake;
  bool _isLoaded = false;

  /// Whether to remind about a retake when a pet's assessment falls due.
  bool get assessmentRetake => _assessmentRetake;

  /// True once the stored preference has been read from disk.
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _assessmentRetake = prefs.getBool(_key) ?? defaultAssessmentRetake;
    _isLoaded = true;
    notifyListeners();
  }

  /// Records [value], persisting it.
  ///
  /// Returns without writing when nothing changed, so a rebuild that echoes
  /// the current value does not churn the store or re-run the scheduler.
  Future<void> setAssessmentRetake(bool value) async {
    if (value == _assessmentRetake) return;
    _assessmentRetake = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  /// Clears the preference — for sign-out, so the next account on the device
  /// does not inherit it.
  Future<void> reset() async {
    _assessmentRetake = defaultAssessmentRetake;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
