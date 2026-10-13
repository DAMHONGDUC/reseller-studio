import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_editing_app_bar.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/order_detail_screen/order_detail_screen.dart';

import '../../support/pump_app.dart';

/// While a section is open, the app bar says so (`docs/rules/SCREENS.md`):
/// it names the section, its close cancels the draft, and a system back
/// leaves edit mode rather than the screen.
void main() {
  Future<void> openFirstSection(WidgetTester tester) async {
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
  }

  testWidgets('item detail: the bar names the open section and closes it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));

    expect(find.byType(AppEditingAppBar), findsNothing);

    await openFirstSection(tester);

    expect(find.byType(AppEditingAppBar), findsOneWidget);
    expect(find.text('Editing Overview'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AppEditingAppBar), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('item detail: system back leaves edit mode, not the screen', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));
    await openFirstSection(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.byType(AppEditingAppBar), findsNothing);
  });

  testWidgets('order detail: the bar names the open section', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrderDetailScreen(orderId: 'ord-1'));
    await openFirstSection(tester);

    expect(find.byType(AppEditingAppBar), findsOneWidget);
    expect(find.text('Editing Order'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.byType(AppEditingAppBar), findsNothing);
  });
}
