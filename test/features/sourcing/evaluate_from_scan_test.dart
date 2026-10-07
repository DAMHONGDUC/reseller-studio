import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/router/app_routes.dart';

/// The buy calculator is reached at the moment it is useful.
///
/// It answers a question asked standing in a shop with the item in one hand,
/// and it used to live three taps down under More. The scanner already has a
/// one-tap card on Home, and a code that matches nothing means one of two
/// things — the seller is about to add it, or they are deciding whether to
/// buy it. The scan result screen offers both.
void main() {
  group('AppRoutes.evaluate', () {
    test('carries the scanned code so the screen opens on its history', () {
      expect(
        AppRoutes.evaluate(code: 'ABC-123'),
        '${AppRoutes.purchaseEvaluator}?code=ABC-123',
      );
    });

    test('escapes a code that would otherwise break the query', () {
      expect(
        AppRoutes.evaluate(code: 'a b&c=d'),
        '${AppRoutes.purchaseEvaluator}?code=a%20b%26c%3Dd',
      );
    });

    test('stays the plain route when there is no code', () {
      // How Sourcing opens it: perfectly usable with nothing scanned, which
      // is why the code is a query parameter and not a second route.
      expect(AppRoutes.evaluate(), AppRoutes.purchaseEvaluator);
      expect(AppRoutes.evaluate(code: ''), AppRoutes.purchaseEvaluator);
    });
  });
}
