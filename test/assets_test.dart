import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Every `assets/v3/...` path referenced from AppAssets.
List<String> _referencedPaths() {
  final source = File('lib/config/assets.dart').readAsStringSync();
  return RegExp(r"'(assets/v3/[^']+)'")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet()
      .toList()
    ..sort();
}

void main() {
  group('asset paths', () {
    test('contain no spaces', () {
      // video_player on Android resolves assets through ExoPlayer's
      // AssetDataSource, which throws FileNotFoundException on any path with
      // a space. Images tolerate it, so the videos failed silently and fell
      // back to their posters.
      final offenders =
          _referencedPaths().where((p) => p.contains(' ')).toList();

      expect(
        offenders,
        isEmpty,
        reason: 'These break video playback on Android:\n'
            '${offenders.join('\n')}',
      );
    });

    test('are declared under a directory pubspec bundles', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/v3/'));
    });

    test('the bundled font is present and is a real font file', () {
      final font = File('assets/fonts/Inter.ttf');
      expect(font.existsSync(), isTrue, reason: 'Inter must be bundled — '
          'without it every text style falls back to the system face.');

      // sfnt magic number, so a stray HTML error page cannot pass as a font.
      final magic = font.readAsBytesSync().sublist(0, 4);
      expect(magic, anyOf([
        equals([0x00, 0x01, 0x00, 0x00]),
        equals('true'.codeUnits),
        equals('OTTO'.codeUnits),
      ]));
    });

    test('every referenced image and webm exists on disk', () {
      // The .mov encodes for Apple platforms are still outstanding; they are
      // expected to be absent and fall back to their posters.
      final missing = _referencedPaths()
          .where((p) => !p.endsWith('.mov'))
          .where((p) => !File(p).existsSync())
          .toList();

      expect(missing, isEmpty, reason: 'Missing assets:\n${missing.join('\n')}');
    });
  });
}
