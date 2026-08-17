import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/screens/report/vet_alert_screen.dart';

/// The vet alert is raised when an assessment lands in the Critical band, so
/// "Find a vet near me" is the one primary action in the app that a worried
/// owner is most likely to press. It used to be `onPressed: () {}`.

Widget _host(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the nearby-vet search', () {
    test('uses Apple Maps on iOS', () {
      final uri = vetSearchUri(platform: TargetPlatform.iOS);

      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['q'], 'veterinarian');
    });

    test('uses Google Maps elsewhere', () {
      final uri = vetSearchUri(platform: TargetPlatform.android);

      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['query'], 'veterinarian');
    });

    test('is an https link on every platform', () {
      // Custom schemes would need an LSApplicationQueriesSchemes entry on
      // iOS and would simply fail to resolve where no maps app is installed.
      for (final platform in TargetPlatform.values) {
        expect(vetSearchUri(platform: platform).scheme, 'https');
      }
    });
  });

  group('the vet alert screen', () {
    testWidgets('Find a vet near me opens the maps search', (tester) async {
      final opened = <Uri>[];

      await tester.pumpWidget(
        _host(
          VetAlertScreen(
            launcher: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Find a vet near me'));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'https');
      expect(opened.single.toString(), contains('veterinarian'));
    });

    testWidgets('a device that cannot open maps is told so', (tester) async {
      await tester.pumpWidget(
        _host(VetAlertScreen(launcher: (uri) async => false)),
      );

      await tester.tap(find.text('Find a vet near me'));
      await tester.pump();

      expect(
        find.textContaining("Couldn't open maps on this device"),
        findsOneWidget,
      );
    });

    testWidgets('a launcher that throws does not crash the screen',
        (tester) async {
      await tester.pumpWidget(
        _host(
          VetAlertScreen(
            launcher: (uri) async => throw Exception('no activity found'),
          ),
        ),
      );

      await tester.tap(find.text('Find a vet near me'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining("Couldn't open maps on this device"),
        findsOneWidget,
      );
    });
  });
}
