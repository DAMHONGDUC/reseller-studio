import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/widgets/money_field.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/repositories/item_repository.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_detail_edit_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_actions_sheet.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **The detail screen edits in place, one section at a time** —
/// `docs/rules/SCREENS.md`. The three ways this erodes are all pinned here:
/// a second Edit opening while a draft is live, a save reaching a field its
/// section does not own, and the old edit screen creeping back into the
/// actions sheet.
void main() {
  Future<ProviderContainer> pumpDetail(WidgetTester tester) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));

    return ProviderScope.containerOf(
      tester.element(find.byType(ItemDetailScreen)),
    );
  }

  Future<Item> read(ProviderContainer container) async {
    final ItemRepository repository = container.read(itemRepositoryProvider);

    return (await repository.watchItem('itm-11').first)!;
  }

  testWidgets('every section that holds fields offers its own Edit', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester);

    // Overview, Pricing and Provenance are above the fold; Description and
    // Notes are built as the list reaches them.
    expect(find.text('Edit'), findsNWidgets(3));

    await tester.scrollUntilVisible(
      find.text('Notes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Listings offers an Edit only when there is a price to move; itm-11 is
    // on no marketplace, so it shows the empty line and no Edit.
    expect(find.text('Listings'), findsOneWidget);
    expect(find.text('Edit'), findsNWidgets(3));
  });

  testWidgets('a listed item sends Edit to Marketplaces management', (
    WidgetTester tester,
  ) async {
    // Owner's rule: the prices live on the screen that can also add a
    // marketplace, so this section links there rather than opening boxes.
    final GoRouter router = await pumpRoutedScreen(
      tester,
      const ItemDetailScreen(itemId: 'itm-4'),
    );

    await tester.scrollUntilVisible(
      find.text('Listings'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Found through its own header rather than by counting Edits: what is
    // built depends on how far the list has scrolled.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SdSectionHeaderV3, 'Listings'),
        matching: find.text('Edit'),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), AppRoutes.crossList('itm-4'));
    // The section itself never opens: no field of its own is on screen.
    expect(find.byType(MoneyField), findsNothing);
  });

  testWidgets('opening one section closes the door on the others', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpDetail(tester);

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    expect(
      container.read(itemDetailEditControllerProvider).editing,
      ItemDetailSection.overview,
    );
    // The open section swapped Edit for Cancel and Save; every other Edit is
    // still drawn but no longer takes a tap.
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      tester
          .widgetList<InkWell>(find.byType(InkWell))
          .where((InkWell tap) => tap.onTap == null)
          .isNotEmpty,
      isTrue,
    );
  });

  testWidgets('a section writes its own fields and leaves the rest alone', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpDetail(tester);
    final Item before = await read(container);

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, before.title),
      'Corrected title',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Item after = await read(container);

    expect(after.title, 'Corrected title');
    // The overview owns the title, the count and the grade — and nothing else.
    expect(after.purchasePrice, before.purchasePrice);
    expect(after.minimumPrice, before.minimumPrice);
    expect(after.status, before.status);
    expect(after.sourceId, before.sourceId);
    // Saving closes the section, which is what puts every other Edit back.
    expect(container.read(itemDetailEditControllerProvider).editing, isNull);
  });

  testWidgets('the actions sheet no longer pushes an edit screen', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemActionsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ItemActionsSheet),
        matching: find.text('Edit'),
      ),
      findsNothing,
    );
  });
}
