import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';

import '../../support/pump_app.dart';

/// A form seeds itself from a record that arrives on a stream, and the only
/// place it learns the record is there is a `build`.
///
/// **Writing the form's provider from that build throws** — Riverpod's "Tried
/// to modify a provider while the widget tree was building". It did, in
/// release as well as debug, and the seller saw an item form that never filled
/// in. `FormSeed.seedOnce` is what defers it; these tests are what stop the
/// direct call coming back.
void main() {
  testWidgets('an edit form fills in without throwing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen(itemId: 'itm-11'));

    expect(tester.takeException(), isNull);
    expect(find.text('Nike windbreaker — XL'), findsOneWidget);
  });

  testWidgets('the title says it is editing, not adding', (
    WidgetTester tester,
  ) async {
    // The screen reads that off the form's own provider, so it is only right
    // once the deferred seed has actually landed.
    await pumpScreen(tester, const ItemFormScreen(itemId: 'itm-11'));

    expect(find.text('Edit item'), findsOneWidget);
  });

  testWidgets('a create form stays empty and throws nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Nike windbreaker — XL'), findsNothing);
  });
}
