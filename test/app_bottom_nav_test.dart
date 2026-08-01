import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypetfit_app/config/theme.dart';
import 'package:mypetfit_app/widgets/app_bottom_nav.dart';

Widget _host({
  required AppTab current,
  required ValueChanged<AppTab> onSelect,
}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        bottomNavigationBar:
            AppBottomNav(current: current, onSelect: onSelect),
      ),
    );

void main() {
  testWidgets('renders four tabs', (tester) async {
    await tester.pumpWidget(_host(current: AppTab.home, onSelect: (_) {}));

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('only the active tab shows its label', (tester) async {
    await tester.pumpWidget(_host(current: AppTab.shop, onSelect: (_) {}));
    await tester.pumpAndSettle();

    // Per the design, inactive tabs are icon-only.
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Report'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('tapping an inactive tab reports the selection', (tester) async {
    AppTab? picked;
    await tester.pumpWidget(
      _host(current: AppTab.home, onSelect: (t) => picked = t),
    );

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    expect(picked, AppTab.shop);
  });

  testWidgets('tapping the active tab does not re-report', (tester) async {
    AppTab? picked;
    await tester.pumpWidget(
      _host(current: AppTab.home, onSelect: (t) => picked = t),
    );

    await tester.tap(find.byIcon(Icons.home_outlined));
    expect(picked, isNull);
  });
}
