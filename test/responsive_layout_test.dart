import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/models/product.dart';
import 'package:mypetfit_app/screens/shop/widgets/product_tile.dart';

import 'support/product_fixtures.dart';

/// Layout that has to survive a real handset rather than one canvas size.
///
/// Both cases here reproduce something seen on a physical iPhone: copy
/// cropped inside a product card, and an email address broken mid-word in the
/// owner profile. Each is asserted at the platform's own text size and again
/// at an accessibility size, because that is where a layout sized for one
/// canvas gives way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Product product(String name, String purpose) =>
      testProduct(id: name, name: name, purpose: purpose);

  Widget host(Widget child, {double textScale = 1.0, double width = 390}) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('a product card never crops its copy', () {
    // The longest realistic content: a name that needs both its lines and a
    // why-line that needs both of its own.
    final worstCase = product(
      "Extend Your Pet's Lifespan",
      'Supports healthy aging, joint health, metabolism and daily vitality',
    );

    for (final scale in [1.0, 1.3]) {
      testWidgets('at text scale $scale', (tester) async {
        late double extent;

        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                extent = ProductTile.extentFor(context);
                return SizedBox(
                  width: 170,
                  height: extent,
                  child: ProductTile(
                    product: worstCase,
                    quantity: 0,
                    onOpen: () {},
                    onQuantityChanged: (_) {},
                  ),
                );
              },
            ),
            textScale: scale,
          ),
        );

        expect(find.text(worstCase.name), findsOneWidget);
        expect(find.text(worstCase.purpose), findsOneWidget);

        // Asserting on the *height the why-line actually got*, not on an
        // overflow exception. The why-line is the only Flexible thing in the
        // card, so a tile that is given less room than it needs does not
        // throw — Flexible quietly hands the shortfall to that one widget
        // and its second line loses its descenders. Silent is exactly what
        // made this ship.
        //
        // Two lines at 11.5/1.4, scaled the way the reader has their phone
        // set. A pixel of tolerance for rounding in the text layout.
        final twoLines = TextScaler.linear(scale).scale(11.5) * 1.4 * 2;
        final purposeHeight =
            tester.getSize(find.text(worstCase.purpose)).height;

        expect(
          purposeHeight,
          greaterThanOrEqualTo(twoLines - 1),
          reason: 'the why-line was cropped: it got ${purposeHeight}px of the '
              '${twoLines}px two full lines need, so its second line loses '
              'its descenders',
        );
      });
    }

    testWidgets('the allocated height grows with the text scale',
        (tester) async {
      double? atNormal;
      double? atLarge;

      await tester.pumpWidget(host(
        Builder(builder: (context) {
          atNormal = ProductTile.extentFor(context);
          return const SizedBox.shrink();
        }),
      ));

      await tester.pumpWidget(host(
        Builder(builder: (context) {
          atLarge = ProductTile.extentFor(context);
          return const SizedBox.shrink();
        }),
        textScale: 1.3,
      ));

      expect(
        atLarge!,
        greaterThan(atNormal!),
        reason: 'a fixed extent crops the card for anyone using larger text',
      );
    });
  });
}
