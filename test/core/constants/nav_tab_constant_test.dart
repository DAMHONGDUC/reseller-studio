import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/nav_tab_constant.dart';
import 'package:reseller_studio/core/router/app_routes.dart';

/// The tab names are what tab analytics is keyed on, and nothing at runtime
/// can tell that they have drifted out of the router's branch order — a wrong
/// name reports a real screen view against the wrong tab, forever, silently.
void main() {
  group('NavTabConstant', () {
    test('names match the five tab roots, in branch order', () {
      // Hard rule 13: the list is closed. If this fails, either a tab was
      // added — which is a product decision — or the two lists have drifted.
      expect(NavTabConstant.analyticsNames, <String>[
        AppRoutes.home.substring(1),
        AppRoutes.inventory.substring(1),
        AppRoutes.orders.substring(1),
        AppRoutes.analytics.substring(1),
        AppRoutes.more.substring(1),
      ]);
    });

    test('an index outside the five is null, never a neighbouring tab', () {
      expect(NavTabConstant.nameAt(0), 'home');
      expect(NavTabConstant.nameAt(4), 'more');
      // Reporting the wrong tab is worse than reporting none.
      expect(NavTabConstant.nameAt(5), isNull);
      expect(NavTabConstant.nameAt(-1), isNull);
    });
  });
}
