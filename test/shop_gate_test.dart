import 'package:flutter_test/flutter_test.dart';

import 'package:mypetfit_app/config/routes.dart';

/// The shop's buying surface is closed for v1.1.0.
///
/// Everything from product detail through checkout is built and looks
/// finished, which is exactly the danger: the Place Order button navigated
/// straight to a success screen, the reference number on it was generated on
/// the device from the clock, no order was written anywhere, and no payment
/// was taken. A customer would have been told their order was placed by an
/// app that recorded nothing. Both stores treat that as deceptive, and the
/// customer would be right to expect goods.
///
/// Browsing and buying are now two switches, because they carry two
/// different risks. Reading the catalogue promises nobody anything: the
/// products are real Firestore documents at their real prices, so
/// [AppRoutes.shopBrowsable] is open. Placing an order is the statement that
/// would be false, so [AppRoutes.shopEnabled] stays shut and checkout, order
/// success and order tracking stay behind it.
///
/// Both gates sit on the routes rather than on the tab because product detail
/// is also reachable from the home dashboard's recommendations and from report
/// history, so gating the tab alone would leave checkout two taps away by
/// another path.
///
/// This test exists to make turning the buying surface back on a deliberate
/// act. If it fails, the question to answer first is not "why is the test red"
/// but "where does an order go now" — and if the answer is still "nowhere",
/// the flag is wrong, not the test.
void main() {
  test('ordering stays closed until orders have somewhere to go', () {
    expect(
      AppRoutes.shopEnabled,
      isFalse,
      reason: 'Enabling this re-exposes a checkout that takes an address '
          'and a payment method and then records nothing. Ship order '
          'persistence and a real payment flow before flipping it.',
    );
  });

  test('browsing the catalogue is open', () {
    // The separation is the point: if someone ever collapses these back into
    // one flag, this pair fails together and says why.
    expect(
      AppRoutes.shopBrowsable,
      isTrue,
      reason: 'The catalogue is real data and commits the user to nothing. '
          'Closing it hides finished, honest UI for no safety gain.',
    );
  });
}
