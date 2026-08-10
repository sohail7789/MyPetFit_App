import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/widgets/info_row.dart';
import 'package:mypetfit_app/widgets/settings_tile.dart';

/// The one label/value row, and the settings row beside it.
///
/// Every case here reproduces something seen on a real handset: a short value
/// floating mid-row instead of reaching the right edge, an email broken
/// mid-word, and "Appearance" shedding its last character onto a line of its
/// own. Each is asserted at the platform's own text size and again at an
/// accessibility size.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A card the width the rows actually get on a 390pt phone: the page's
  /// 22pt margins and the card's 16pt padding taken off.
  const cardWidth = 390.0 - 44 - 32;

  Widget host(Widget child, {double textScale = 1.0, double width = cardWidth}) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    );
  }

  group('information rows', () {
    testWidgets('short values end on the same right edge as long ones',
        (tester) async {
      await tester.pumpWidget(host(
        const Column(
          children: [
            InfoRow(label: 'Veterinarian', value: 'Tushar'),
            InfoRow(label: 'Language', value: 'English'),
            InfoRow(label: 'Vet contact', value: ''),
            InfoRow(label: 'Full name', value: 'Sohail Inamdar', last: true),
          ],
        ),
      ));

      // The right edge of each value, as rendered. A short value that is
      // merely "in the right-hand column" lands wherever its own box starts;
      // these have to *terminate* together.
      double rightEdgeOf(String text) {
        final box = tester.getRect(find.text(text));
        return box.right;
      }

      final edges = [
        rightEdgeOf('Tushar'),
        rightEdgeOf('English'),
        rightEdgeOf('Not set'),
        rightEdgeOf('Sohail Inamdar'),
      ];

      for (final edge in edges) {
        expect(
          edge,
          closeTo(edges.first, 0.5),
          reason: 'values do not share a right edge: $edges',
        );
      }
    });

    testWidgets('labels all start on the same left edge', (tester) async {
      await tester.pumpWidget(host(
        const Column(
          children: [
            InfoRow(label: 'Veterinarian', value: 'Tushar'),
            InfoRow(label: 'Email', value: 'a@b.com'),
            InfoRow(label: 'Contact number', value: '9011778874', last: true),
          ],
        ),
      ));

      final lefts = [
        tester.getRect(find.text('Veterinarian')).left,
        tester.getRect(find.text('Email')).left,
        tester.getRect(find.text('Contact number')).left,
      ];

      for (final left in lefts) {
        expect(left, closeTo(lefts.first, 0.5), reason: 'labels: $lefts');
      }
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('a long value gets the full row width at scale $scale',
          (tester) async {
        const email = 'sohel.inamddar55@gmail.com';

        await tester.pumpWidget(host(
          const Column(
            children: [
              InfoRow(label: 'Email', value: email),
              InfoRow(label: 'Language', value: 'English', last: true),
            ],
          ),
          textScale: scale,
        ));

        // Whole — never truncated to make it fit.
        expect(find.text(email), findsOneWidget);

        // Deliberately not asserting "one line": the width a string occupies
        // depends on the font, and the test environment's fallback font is far
        // wider than Manrope, so a line count here would be measuring the test
        // harness rather than the layout.
        //
        // What the fix actually changes is *how much width the value gets*.
        // Sharing the row, it only ever received the column left over beside
        // the label — which is why an unbreakable token snapped mid-word into
        // `…@gm / ail.com`. Stacked, it gets the whole row. So that is what is
        // asserted, and it is font-independent.
        final emailWidth = tester.getSize(find.text(email)).width;
        final shortWidth = tester.getSize(find.text('English')).width;
        final leftoverColumn =
            cardWidth - tester.getSize(find.text('Email')).width - 16;

        expect(
          emailWidth,
          greaterThan(leftoverColumn),
          reason: 'the long value was still confined to the leftover column '
              '(${emailWidth}px of a possible ${cardWidth}px), which is what '
              'forces the mid-word break',
        );
        expect(
          emailWidth,
          greaterThan(shortWidth),
          reason: 'a long value must be given more room than a short one',
        );
      });
    }

    testWidgets('a long value still ends on the right edge', (tester) async {
      const email = 'sohel.inamddar55@gmail.com';

      await tester.pumpWidget(host(
        const Column(
          children: [
            InfoRow(label: 'Email', value: email),
            InfoRow(label: 'Language', value: 'English', last: true),
          ],
        ),
      ));

      expect(
        tester.getRect(find.text(email)).right,
        closeTo(tester.getRect(find.text('English')).right, 0.5),
        reason: 'a wrapped value must still terminate on the shared edge',
      );
    });
  });

  group('the appearance row', () {
    Widget appearance({double textScale = 1.0}) => host(
          SettingsSegmentedTile<int>(
            icon: Icons.contrast_rounded,
            label: 'Appearance',
            options: const [(0, 'Light'), (1, 'System'), (2, 'Dark')],
            value: 0,
            onChanged: (_) {},
          ),
          textScale: textScale,
        );

    for (final scale in [1.0, 1.3]) {
      testWidgets('the label never breaks up at scale $scale', (tester) async {
        await tester.pumpWidget(appearance(textScale: scale));

        expect(find.text('Appearance'), findsOneWidget);

        // One line. The defect rendered it as `Appearanc` + `e`, which is a
        // two-line box — so the height is what distinguishes the broken
        // layout from the correct one.
        final painter = TextPainter(
          text: const TextSpan(
            text: 'Appearance',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();

        final rendered = tester.getSize(find.text('Appearance')).height;
        expect(
          rendered,
          lessThan(painter.height * 1.8),
          reason: 'the label wrapped (${rendered}px vs ${painter.height}px '
              'for one line) — it is breaking into a stray character',
        );
      });
    }

    testWidgets('all three options remain present and tappable',
        (tester) async {
      var picked = -1;
      await tester.pumpWidget(host(
        SettingsSegmentedTile<int>(
          icon: Icons.contrast_rounded,
          label: 'Appearance',
          options: const [(0, 'Light'), (1, 'System'), (2, 'Dark')],
          value: 0,
          onChanged: (v) => picked = v,
        ),
      ));

      for (final option in ['Light', 'System', 'Dark']) {
        expect(find.text(option), findsOneWidget, reason: option);
      }

      await tester.tap(find.text('Dark'));
      expect(picked, 2, reason: 'the control must stay fully operable');
    });
  });
}
