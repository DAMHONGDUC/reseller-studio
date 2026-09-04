import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';

import '../../support/pump_app.dart';

/// The scanner's unknown-code dialog offers to "add an item and keep the code
/// on it", and for a while it kept nothing: it pushed the bare add route and
/// the seller retyped the digits they had just scanned.
///
/// These pin both halves — the route that carries the code, and the form that
/// puts it in the box.
void main() {
  test('the add route carries a scanned code, and omits an empty one', () {
    expect(
      AppRoutes.addItemWithCode(code: '012345678905'),
      '${AppRoutes.addItem}?code=012345678905',
    );
    expect(AppRoutes.addItemWithCode(), AppRoutes.addItem);
    expect(AppRoutes.addItemWithCode(code: ''), AppRoutes.addItem);
  });

  test('a code needing escaping survives the round trip', () {
    final Uri uri = Uri.parse(AppRoutes.addItemWithCode(code: 'a b&c'));

    expect(uri.queryParameters['code'], 'a b&c');
  });

  testWidgets('a create form opens with the scanned code filled in', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen(initialBarcode: '5012345'));

    expect(tester.takeException(), isNull);
    // The identifiers section sits below the fold, so the field has to be
    // scrolled to before it is built at all.
    await tester.scrollUntilVisible(
      find.text('5012345'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('5012345'), findsOneWidget);
  });

  testWidgets('an edit form ignores it — that item has its own code', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const ItemFormScreen(itemId: 'itm-11', initialBarcode: '5012345'),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('5012345'), findsNothing);
  });
}
