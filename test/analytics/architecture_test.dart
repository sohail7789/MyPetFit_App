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
  const pureDirectories = [
    'lib/analytics/models',
    'lib/analytics/domain',
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
    test('models and domain import no Flutter', () {
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

    test('models and domain never reach for a provider', () {
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
