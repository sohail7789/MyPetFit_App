import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable language.
///
/// [available] marks whether the app actually has strings for it. Only
/// English does today, so the rest are listed but not selectable — a picker
/// that silently accepts a language it cannot render is worse than one that
/// says so.
class AppLanguage {
  final String code;

  /// Short badge shown in the picker and on the sign-in chip.
  final String glyph;

  final String name;

  /// The language's own name, e.g. "हिन्दी".
  final String native;

  final bool available;

  const AppLanguage({
    required this.code,
    required this.glyph,
    required this.name,
    required this.native,
    this.available = false,
  });
}

/// Holds the user's language preference.
///
/// Deliberately not wired to `flutter_localizations` yet: the 45 assessment
/// questions, the nine category names and the consent text all need a
/// translator before a second locale means anything. This stores the choice
/// and keeps the UI honest until those land.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language';
  static const fallbackCode = 'en';

  static const List<AppLanguage> supported = [
    AppLanguage(
      code: 'en',
      glyph: 'EN',
      name: 'English',
      native: 'Default',
      available: true,
    ),
    AppLanguage(code: 'hi', glyph: 'हि', name: 'Hindi', native: 'हिन्दी'),
    AppLanguage(code: 'mr', glyph: 'मर', name: 'Marathi', native: 'मराठी'),
  ];

  String _code = fallbackCode;
  bool _isLoaded = false;

  String get code => _code;
  bool get isLoaded => _isLoaded;

  AppLanguage get current => supported.firstWhere(
        (l) => l.code == _code,
        orElse: () => supported.first,
      );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null && supported.any((l) => l.code == stored)) {
      _code = stored;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Selects [code]. Languages without strings are ignored rather than
  /// leaving the app in a locale it cannot render.
  Future<void> select(String code) async {
    final match = supported.firstWhere(
      (l) => l.code == code,
      orElse: () => supported.first,
    );
    if (!match.available || match.code == _code) return;

    _code = match.code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _code);
  }
}
