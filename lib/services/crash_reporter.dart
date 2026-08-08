import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Where an unhandled error goes.
///
/// One tiny interface rather than calling [FirebaseCrashlytics] from the
/// hooks directly, for one reason: the hooks are the part with the logic
/// worth testing — re-entrancy, failure tolerance, keeping the original
/// error — and none of that can be exercised against a native crash
/// reporter. It is deliberately narrow, and that narrowness is a safety
/// property: there is **no channel here for user data**, so nothing about a
/// pet, an owner or an assessment can be attached to a report by accident.
abstract class CrashSink {
  Future<void> recordFlutterError(FlutterErrorDetails details);

  Future<void> recordError(Object error, StackTrace? stack, {bool fatal});
}

/// The production sink.
///
/// Carries the error and its stack and nothing else. No user identifier, no
/// custom keys, no breadcrumbs: this app's errors can arise while a health
/// questionnaire is on screen, and a crash report is not a place to put
/// somebody's answers about their animal. A guard test asserts this file
/// never grows those calls.
class CrashlyticsSink implements CrashSink {
  const CrashlyticsSink();

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      FirebaseCrashlytics.instance.recordFlutterError(details);

  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) =>
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
}

/// Installs the global error hooks.
///
/// **Two hooks, disjoint by design.** [FlutterError.onError] receives errors
/// raised inside the framework — a build, a layout, a paint.
/// [PlatformDispatcher.instance.onError] receives uncaught asynchronous
/// errors that reach the engine. An error travels one path or the other, so
/// nothing is reported twice.
///
/// `runZonedGuarded` is deliberately **not** used. Wrapping `runApp` in a
/// guarded zone would catch the same asynchronous errors the platform
/// dispatcher already delivers, and every one of them would be filed twice.
class CrashReporter {
  const CrashReporter._();

  /// Guards against an error inside the reporter being reported, failing,
  /// and being reported again.
  static bool _reporting = false;

  /// Wires the hooks to [sink].
  ///
  /// Call **after** Firebase is up: Crashlytics is a Firebase product and
  /// reaching for it before initialisation throws. See
  /// [FirebaseStartupProvider] — the app only installs these once the
  /// connection is known good, and simply runs without crash reporting when
  /// it is not, because an app that cannot start is worse than one that
  /// cannot report.
  static void install({CrashSink sink = const CrashlyticsSink()}) {
    FlutterError.onError = (details) {
      // The developer's own diagnostics come first and are untouched: the
      // console output and the red box are how a Flutter error is meant to
      // read while building the app.
      FlutterError.presentError(details);
      _report(() => sink.recordFlutterError(details));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _report(() => sink.recordError(error, stack, fatal: true));
      // Handled as far as the engine is concerned. Returning false would
      // leave it to print the error again, which is the duplicate this
      // arrangement exists to avoid.
      return true;
    };
  }

  /// Restores Flutter's own handlers. For tests, so one case cannot leak its
  /// hooks into the next.
  @visibleForTesting
  static void uninstall() {
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;
    _reporting = false;
  }

  /// Runs [send], and never lets its failure become the app's problem.
  ///
  /// A crash reporter that throws while reporting a crash would replace the
  /// original error with its own — the one thing worse than losing the
  /// report is losing the error it was about.
  static void _report(Future<void> Function() send) {
    if (_reporting) return;
    _reporting = true;

    try {
      send().catchError(_swallow);
    } catch (error) {
      _swallow(error);
    } finally {
      _reporting = false;
    }
  }

  static void _swallow(Object error) {
    // Deliberately silent in release: there is nowhere left to report a
    // failure of the thing that does the reporting.
    if (kDebugMode) {
      debugPrint('Crash report could not be sent: $error');
    }
  }
}
