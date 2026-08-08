import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The analytics module's reuse promise, enforced rather than documented.
///
/// `models/` and `domain/` are meant to be plain Dart — runnable from a web
/// dashboard, a veterinarian portal, a server-side job or a CLI, none of
/// which have a Flutter widget tree. A convention decays over five years; a
/// failing test does not.
///
/// This is the test that makes "the UI should not care where data comes
/// from" true instead of aspirational.
void main() {
  /// Everything that must run without a widget tree — a server-side job, a
  /// PDF renderer, a web dashboard or a veterinarian portal's backend.
  const pureDirectories = [
    'lib/analytics/models',
    'lib/analytics/domain',
    'lib/analytics/services',
    'lib/analytics/presentation',
  ];

  List<File> dartFilesIn(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  group('analytics purity', () {
    test('models, domain, services and presentation import no Flutter', () {
      final offenders = <String>[];

      for (final directory in pureDirectories) {
        for (final file in dartFilesIn(directory)) {
          for (final line in file.readAsLinesSync()) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('import ')) continue;
            if (trimmed.contains('package:flutter/')) {
              offenders.add('${file.path}: $trimmed');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'analytics/models and analytics/domain must be plain Dart so '
            'the engine can run outside a Flutter app. Move anything needing '
            'Flutter into analytics/widgets.\n${offenders.join('\n')}',
      );
    });

    test('the pure layers carry no cloud dependency', () {
      // The rule that keeps the recommendation honest. `Product` is a
      // Firestore-backed type, so a domain that returned one would drag
      // Firebase into a veterinarian portal's backend, a digest job and a
      // server-rendered PDF. Analytics names a category; whichever surface
      // owns a catalog resolves it to stock.
      const cloudPackages = [
        'package:cloud_firestore/',
        'package:firebase_core/',
        'package:firebase_auth/',
        'package:firebase_storage/',
      ];

      final offenders = <String>[];

      for (final directory in pureDirectories) {
        for (final file in dartFilesIn(directory)) {
          for (final line in file.readAsLinesSync()) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('import ')) continue;
            if (cloudPackages.any(trimmed.contains)) {
              offenders.add('${file.path}: $trimmed');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'analytics/models, domain, services and presentation must run '
            'with no Firebase in scope.\n${offenders.join('\n')}',
      );
    });

    test('the pure layers never read the wall clock', () {
      // The invariant the whole module's determinism rests on: the same
      // history and the same `now` always produce the same answer, which is
      // what lets a snapshot be cached, a test pin a date, and a countdown
      // move as time passes instead of freezing at the instant a snapshot
      // was built.
      //
      // `DateTime` itself is fine — dates are the data. Reading *the current*
      // one inside a calculator is what breaks it, and every existing test
      // would still pass afterwards, because they all pass `now:` explicitly.
      // That is precisely why this needs a mechanical guard rather than a
      // convention.
      final offenders = <String>[];

      for (final directory in pureDirectories) {
        for (final file in dartFilesIn(directory)) {
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            // Prose about the rule is not a breach of it.
            final code = line.split('//').first;
            if (code.contains('DateTime.now()') ||
                code.contains('DateTime.timestamp()')) {
              offenders.add('${file.path}:${i + 1}: ${line.trim()}');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'analytics/models, domain, services and presentation must take '
            'the instant to judge against as a parameter — never read it. '
            'Pass `now` in from the widget or the caller.\n'
            '${offenders.join('\n')}',
      );
    });

    test('the pure layers never reach for a provider', () {
      // Providers are the adapter's business. A calculator that reads one
      // cannot be handed a smart collar's history, which is the whole point
      // of the module.
      final offenders = <String>[];

      for (final directory in pureDirectories) {
        for (final file in dartFilesIn(directory)) {
          for (final line in file.readAsLinesSync()) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('import ')) continue;
            if (trimmed.contains('/providers/') ||
                trimmed.contains('package:provider/')) {
              offenders.add('${file.path}: $trimmed');
            }
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('only the adapter layer knows the app providers exist', () {
      // If a widget or a service starts importing QuizProvider, the module
      // has quietly stopped being reusable and this is where that shows up.
      final offenders = <String>[];

      for (final directory in [
        'lib/analytics/models',
        'lib/analytics/domain',
        'lib/analytics/services',
        'lib/analytics/widgets',
      ]) {
        for (final file in dartFilesIn(directory)) {
          for (final line in file.readAsLinesSync()) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('import ')) continue;
            if (trimmed.contains('/providers/')) {
              offenders.add('${file.path}: $trimmed');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Provider access belongs in analytics/adapters.\n'
            '${offenders.join('\n')}',
      );
    });

    test('the pure layers exist and are not empty', () {
      // Guards against the test above passing because someone deleted or
      // renamed the directories it inspects.
      for (final directory in pureDirectories) {
        expect(
          dartFilesIn(directory),
          isNotEmpty,
          reason: '$directory has no Dart files — the purity checks above '
              'would pass vacuously',
        );
      }
    });
  });
}
