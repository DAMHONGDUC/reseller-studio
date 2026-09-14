import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/core/widgets/money_field.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_form_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/providers.dart';

import '../../support/pump_app.dart';

/// What an item costs on each marketplace is edited in the item form —
/// owner's rule.
///
/// Cost, asking price and minimum were already here; the number a buyer
/// actually sees was two screens away, which made the form the wrong place to
/// answer "what is this priced at".
void main() {
  /// `itm-4` in the seeded dataset is live on eBay and Depop.
  Future<List<Listing>> listingsFor(
    ProviderContainer container,
    String itemId,
  ) async {
    container.listen<AsyncValue<List<Listing>>>(
      listingsForItemProvider(itemId),
      (AsyncValue<List<Listing>>? _, AsyncValue<List<Listing>> _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    return container.read(listingsForItemProvider(itemId)).value ??
        const <Listing>[];
  }

  /// The marketplace prices sit below the fold: a `ListView` does not build
  /// what is off screen, so the section has to be scrolled to before it can
  /// be found.
  Future<void> scrollToPrices(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('eBay'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the form shows a price field per live listing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen(itemId: 'itm-4'));
    await scrollToPrices(tester);

    expect(find.text('eBay'), findsOneWidget);
    expect(find.text('Depop'), findsOneWidget);
  });

  testWidgets('an item on nothing shows no marketplace fields', (
    WidgetTester tester,
  ) async {
    // A section that rendered an empty heading would be a title over a gap.
    await pumpScreen(tester, const ItemFormScreen(itemId: 'itm-11'));

    expect(find.text('eBay'), findsNothing);
  });

  testWidgets('editing one and saving writes only that listing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen(itemId: 'itm-4'));
    await scrollToPrices(tester);

    final Finder ebay = find.ancestor(
      of: find.text('eBay'),
      matching: find.byType(MoneyField),
    );

    await tester.enterText(
      find.descendant(of: ebay, matching: find.byType(EditableText)),
      '150',
    );
    await tester.pumpAndSettle();

    final ItemFormState state = ProviderScope.containerOf(
      tester.element(find.byType(ItemFormScreen)),
    ).read(itemFormControllerProvider);

    // Only the edited listing is in the map — an untouched one is absent, so
    // saving an item nobody repriced writes no listing at all.
    expect(state.listingPrices, hasLength(1));
    expect(state.listingPrices.values.single, const Money(15000, 'USD'));
  });

  test('submit writes the repriced listing and leaves the rest', () async {
    final ProviderContainer container = mockContainer();
    final List<Listing> before = await listingsFor(container, 'itm-4');
    final Listing ebay = before.firstWhere(
      (Listing listing) => listing.marketplaceId == 'ebay',
    );
    final ItemFormController controller = container.read(
      itemFormControllerProvider.notifier,
    );

    controller.seed(
      (await container.read(itemRepositoryProvider).watchItem('itm-4').first)!,
    );
    controller.setListingPrice(ebay.id, const Money(15000, 'USD'));

    await controller.submit(title: 'Anything');

    final List<Listing> after = await listingsFor(container, 'itm-4');

    expect(
      after.firstWhere((Listing l) => l.id == ebay.id).price,
      const Money(15000, 'USD'),
    );
    expect(
      after.where((Listing l) => l.id != ebay.id).map((Listing l) => l.price),
      before.where((Listing l) => l.id != ebay.id).map((Listing l) => l.price),
      reason: 'a listing nobody touched must not be rewritten',
    );
  });
}
