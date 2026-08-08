import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/services/crash_reporter.dart';

/// Sprint 4, P1-2 — errors have somewhere to go, and reporting them can never
/// become the problem.
///
/// The app had no global error hooks at all: `FlutterError.onError` and
/// `PlatformDispatcher.instance.onError` were both untouched, so in release a
/// framework error printed to a console nobody reads and an uncaught async
/// error was simply lost. Nothing could answer why a real user's onboarding,
/// sync or PDF export failed.
///
/// What is testable here is the wiring and its failure behaviour. Whether a
/// report reaches the Crashlytics dashboard is native infrastructure and is
/// stated as device work, not asserted here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(CrashReporter.uninstall);

  group('the hooks are installed', () {
    test('a framework error reaches the sink', () {
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      final details = FlutterErrorDetails(
        exception: StateError('a widget misbehaved'),
        stack: StackTrace.current,
        library: 'widgets library',
      );

      // Exactly what the framework does when a build throws.
      FlutterError.reportError(details);

      expect(sink.flutterErrors, hasLength(1));
      expect(sink.flutterErrors.single.exception, isA<StateError>());
    });

    test('an uncaught async error reaches the sink', () async {
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      final handler = PlatformDispatcher.instance.onError;
      expect(handler, isNotNull, reason: 'no async error hook was installed');

      final error = Exception('an unawaited future rejected');
      final handled = handler!(error, StackTrace.current);

      expect(handled, isTrue, reason: 'the engine would print it a second time');
      expect(sink.errors, hasLength(1));
      expect(sink.errors.single.error, same(error));
    });

    test('an async error is recorded as fatal, a framework error is not', () {
      // Crashlytics separates the two, and the distinction is what makes a
      // crash-free-users number mean anything.
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      PlatformDispatcher.instance.onError!(
        Exception('boom'),
        StackTrace.current,
      );

      expect(sink.errors.single.fatal, isTrue);
    });
  });

  group('the original error survives', () {
    test('the framework still presents it for the developer', () {
      // The red box and the console output are how a Flutter error is meant
      // to read while building the app; reporting must not replace them.
      final sink = _RecordingSink();
      final presented = <FlutterErrorDetails>[];

      final previous = FlutterError.presentError;
      FlutterError.presentError = presented.add;
      addTearDown(() => FlutterError.presentError = previous);

      CrashReporter.install(sink: sink);

      final details = FlutterErrorDetails(
        exception: StateError('a widget misbehaved'),
        stack: StackTrace.current,
      );
      FlutterError.reportError(details);

      expect(presented, hasLength(1));
      expect(presented.single.exception, same(details.exception));
    });

    test('the error and stack are passed through unchanged', () {
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      final error = Exception('the original');
      final stack = StackTrace.current;

      PlatformDispatcher.instance.onError!(error, stack);

      expect(sink.errors.single.error, same(error));
      expect(sink.errors.single.stack, same(stack));
    });
  });

  group('a failing reporter is never the app’s problem', () {
    test('a sink that throws synchronously does not escape', () {
      CrashReporter.install(sink: _ThrowingSink());

      // If this propagated it would replace the app's error with the
      // reporter's, which is worse than losing the report.
      expect(
        () => FlutterError.reportError(
          FlutterErrorDetails(exception: StateError('original')),
        ),
        returnsNormally,
      );
    });

    test('a sink whose future rejects does not escape', () async {
      CrashReporter.install(sink: _RejectingSink());

      expect(
        () => PlatformDispatcher.instance.onError!(
          Exception('original'),
          StackTrace.current,
        ),
        returnsNormally,
      );

      // And the rejection does not surface later as an unhandled error.
      await Future<void>.delayed(Duration.zero);
    });

    test('an error raised while reporting does not loop', () {
      // A sink that itself reports through the same hook is the shape of an
      // infinite loop: report -> throw -> report -> throw.
      final sink = _ReentrantSink();
      CrashReporter.install(sink: sink);

      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('original')),
      );

      expect(
        sink.calls,
        1,
        reason: 'the reporter re-entered itself',
      );
    });
  });

  group('nothing about the user goes into a report', () {
    test('the sink has no channel for anything but an error', () {
      // A structural guarantee rather than a promise: the interface accepts
      // an error and a stack, so there is nowhere to put a pet, an owner or
      // an assessment answer.
      final sink = _RecordingSink();
      CrashReporter.install(sink: sink);

      PlatformDispatcher.instance.onError!(
        Exception('boom'),
        StackTrace.current,
      );

      final recorded = sink.errors.single;
      expect(recorded.error, isA<Exception>());
      expect(recorded.stack, isA<StackTrace>());
    });

    test('the production sink attaches no identity or custom keys', () {
      // The mechanical guard. Crashlytics offers setUserIdentifier,
      // setCustomKey and log(), and every one of them is a way for a health
      // answer or an account identifier to end up in a crash report. This
      // fails the moment one appears.
      final source =
          File('lib/services/crash_reporter.dart').readAsStringSync();

      for (final forbidden in const [
        'setUserIdentifier',
        'setCustomKey',
        'setCustomKeys',
        '.log(',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: 'crash_reporter.dart calls $forbidden — a crash report is '
              'not a place for user data',
        );
      }
    });
  });

  group('uninstall', () {
    test('restores Flutter’s own handlers', () {
      CrashReporter.install(sink: _RecordingSink());
      CrashReporter.uninstall();

      expect(FlutterError.onError, equals(FlutterError.presentError));
      expect(PlatformDispatcher.instance.onError, isNull);
    });
  });
}

typedef _Recorded = ({Object error, StackTrace? stack, bool fatal});

class _RecordingSink implements CrashSink {
  final flutterErrors = <FlutterErrorDetails>[];
  final errors = <_Recorded>[];

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async =>
      flutterErrors.add(details);

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false}) async {
    errors.add((error: error, stack: stack, fatal: fatal));
  }
}

class _ThrowingSink implements CrashSink {
  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      throw StateError('the reporter itself broke');

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {bool fatal = false}) =>
      throw StateError('the reporter itself broke');
}

class _RejectingSink implements CrashSink {
  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async =>
      throw StateError('upload failed');

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false}) async {
    throw StateError('upload failed');
  }
}

/// Reports through the same hook it is serving, which is how a reporting loop
/// starts.
class _ReentrantSink implements CrashSink {
  int calls = 0;

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    calls++;
    FlutterError.reportError(
      FlutterErrorDetails(exception: StateError('raised while reporting')),
    );
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {bool fatal = false}) async {
    calls++;
  }
}
