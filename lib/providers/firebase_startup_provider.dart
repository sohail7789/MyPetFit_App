import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

enum FirebaseStatus {
  /// The first attempt has not finished. Distinct from [failed] so the app
  /// shows a launch state rather than an error it has no grounds for yet.
  connecting,

  ready,

  /// Firebase is unavailable. Nothing that needs an account can work, and
  /// the app must say so rather than carry on as though it could.
  failed,
}

/// Whether Firebase is actually available.
///
/// This used to be a `try`/`catch` in `main()` whose only response was a
/// `debugPrint` behind `kDebugMode`. In release the failure was invisible and
/// the app launched anyway — into a state where every account operation
/// throws `[core/no-app]` deep inside a provider. A signed-out user reached
/// the sign-in screen and got a raw platform exception in a snackbar; a
/// returning user got as far as the startup restore before anything admitted
/// something was wrong.
///
/// Made explicit here so the app can refuse to pretend, and offer a retry
/// that actually retries.
class FirebaseStartupProvider extends ChangeNotifier {
  /// The initialisation itself, injectable so the failure and retry paths are
  /// testable without a Firebase project.
  final Future<void> Function() _initialise;

  FirebaseStartupProvider({
    @visibleForTesting Future<void> Function()? initialise,
  }) : _initialise = initialise ?? _initialiseFirebase;

  FirebaseStatus _status = FirebaseStatus.connecting;
  Object? _error;
  bool _inFlight = false;

  FirebaseStatus get status => _status;

  bool get isReady => _status == FirebaseStatus.ready;

  bool get hasFailed => _status == FirebaseStatus.failed;

  /// What went wrong, for diagnostics only.
  ///
  /// Never rendered: a platform exception tells a user nothing they can act
  /// on and can carry project identifiers. The UI shows its own words.
  Object? get error => _error;

  /// Brings Firebase up, once.
  ///
  /// Safe to call repeatedly — a second call while one is in flight is
  /// ignored, and a call once ready does nothing. That is what stops a retry
  /// from issuing a second `Firebase.initializeApp`, which throws
  /// `duplicate-app` rather than helping.
  Future<void> connect() async {
    if (_inFlight || _status == FirebaseStatus.ready) return;

    _inFlight = true;
    if (_status == FirebaseStatus.failed) {
      // A retry is a fresh attempt, not a lingering error.
      _status = FirebaseStatus.connecting;
      _error = null;
      notifyListeners();
    }

    try {
      await _initialise();
      _status = FirebaseStatus.ready;
      _error = null;
    } catch (error, stack) {
      _status = FirebaseStatus.failed;
      _error = error;
      // Enough to debug, nothing that identifies a person. The options
      // carry project and API identifiers, so they are not logged.
      if (kDebugMode) {
        debugPrint('Firebase initialisation failed: $error');
        debugPrintStack(stackTrace: stack);
      }
    } finally {
      _inFlight = false;
    }

    notifyListeners();
  }
}

/// The real initialisation.
///
/// Guards against a second `initializeApp`: Firebase throws `duplicate-app`
/// when the default app already exists, so a retry that raced a slow first
/// attempt would turn a recoverable failure into a permanent one.
Future<void> _initialiseFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
