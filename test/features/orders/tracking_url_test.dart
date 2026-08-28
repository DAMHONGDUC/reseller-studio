import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/carriers/carrier_constant.dart';
import 'package:reseller_studio/features/orders/orders_tracking_constant.dart';

/// A row that opens the wrong page is worse than one that does not open: the
/// seller reads "not found" and starts wondering whether the parcel is lost.
void main() {
  test('a known carrier gets its own tracking page', () {
    expect(
      OrdersTrackingConstant.url(carrier: 'USPS', number: '9400 1111'),
      contains('usps.com'),
    );
  });

  test('the number is encoded, so a space cannot break the URL', () {
    final String url = OrdersTrackingConstant.url(
      carrier: 'UPS',
      number: '1Z 999 AA1',
    )!;

    expect(url, isNot(contains(' ')));
    expect(url, contains('1Z%20999%20AA1'));
  });

  test('an unknown carrier, Other, or no number opens nothing', () {
    expect(OrdersTrackingConstant.url(carrier: 'Other', number: '123'), isNull);
    expect(
      OrdersTrackingConstant.url(carrier: 'Some Local Courier', number: '123'),
      isNull,
    );
    expect(OrdersTrackingConstant.url(carrier: 'USPS', number: '  '), isNull);
    expect(OrdersTrackingConstant.url(carrier: null, number: '123'), isNull);
  });

  test('every default carrier has a tracking template', () {
    for (final CarrierSeed carrier in CarrierConstant.defaults) {
      expect(OrdersTrackingConstant.urlTemplates, contains(carrier.name));
    }
  });

  test('every template has a slot for the number', () {
    for (final String template in OrdersTrackingConstant.urlTemplates.values) {
      expect(template, contains('{n}'));
    }
  });
}
