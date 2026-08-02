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
      // Images tolerate spaces, but video_player on Android resolves assets
      // through ExoPlayer's AssetDataSource, which throws
      // FileNotFoundException on any path containing one — so a clip added
      // back later would fail silently. Cheap to keep enforcing now.
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

    test('the bundled fonts are present and are real font files', () {
      // The UI face, plus the two static instances the report PDF embeds —
      // the pdf package takes one weight per Font and cannot read the
      // variable build the app itself uses.
      const fonts = [
        'assets/fonts/Manrope.ttf',
        'assets/pdf/Manrope-Regular.ttf',
        'assets/pdf/Manrope-ExtraBold.ttf',
      ];

      for (final path in fonts) {
        final font = File(path);
        expect(font.existsSync(), isTrue,
            reason: '$path must be bundled — without it every text style '
                'falls back to the system face.');

        // sfnt magic number, so a stray HTML error page (a 404 from a font
        // CDN, say) cannot pass as a font.
        final magic = font.readAsBytesSync().sublist(0, 4);
        expect(magic, anyOf([
          equals([0x00, 0x01, 0x00, 0x00]),
          equals('true'.codeUnits),
          equals('OTTO'.codeUnits),
        ]), reason: '$path is not a font file.');
      }
    });

    test('every referenced asset exists on disk', () {
      // No exemptions any more: the outstanding .mov encodes and the WebM
      // clips they were meant to replace are all gone from AppAssets, so
      // every path it names should resolve to a real file.
      final missing =
          _referencedPaths().where((p) => !File(p).existsSync()).toList();

      expect(missing, isEmpty, reason: 'Missing assets:\n${missing.join('\n')}');
    });

    test('bundles no video, which Android cannot composite transparently', () {
      final clips = Directory('assets/v3')
          .listSync()
          .map((e) => e.path)
          .where((p) => p.endsWith('.webm') || p.endsWith('.mov'))
          .toList();

      expect(
        clips,
        isEmpty,
        reason: 'These ship in the APK but nothing plays them:\n'
            '${clips.join('\n')}\n'
            'See DesignVideo for how to reinstate motion properly.',
      );
    });
  });
}
