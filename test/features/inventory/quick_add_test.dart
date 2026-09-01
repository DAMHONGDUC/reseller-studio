import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/quick_add_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/quick_add_screen/quick_add_screen.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/mock_data/data/in_memory_repositories.dart';
import 'package:reseller_studio/features/mock_data/domain/mock_dataset.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  group('QuickAddController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          dataModeProvider.overrideWith(_AlwaysMock.new),
          mockStoreProvider.overrideWith(
            (Ref ref) => MockStore(MockDataset.seed(now: testNow)),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('creates an item from a title alone', () async {
      final QuickAddController controller = container.read(
        quickAddControllerProvider.notifier,
      );

      await warmUp(container);

      final int before = container.read(itemsProvider).value!.length;

      controller.updateTitle('Nike Air Max 90');

      final String? id = await controller.submit();
      final List<Item> after = container.read(itemsProvider).value!;

      expect(id, isNotNull);
      expect(after.length, before + 1);

      final Item created = after.firstWhere((Item i) => i.id == id);

      // Hard rule 2: only a title was given, and that is enough. The item
      // lands as a draft rather than as sellable inventory.
      expect(created.title, 'Nike Air Max 90');
      expect(created.status, ItemStatus.draft);
      expect(created.quantity, 1);
      expect(created.purchasePrice, isNull);
      expect(created.minimumPrice, isNull);
      expect(created.photoUrls, isEmpty);
    });

    test('refuses an empty or whitespace-only title', () async {
      final QuickAddController controller = container.read(
        quickAddControllerProvider.notifier,
      );

      await warmUp(container);

      final int before = container.read(itemsProvider).value!.length;

      expect(await controller.submit(), isNull);

      controller.updateTitle('   ');

      expect(controller.state.canSubmit, isFalse);
      expect(await controller.submit(), isNull);
      expect(container.read(itemsProvider).value!.length, before);
    });

    test('trims the title it stores', () async {
      final QuickAddController controller = container.read(
        quickAddControllerProvider.notifier,
      );

      await warmUp(container);
      controller.updateTitle('  Levi 501  ');

      final String? id = await controller.submit();
      final Item created = container
          .read(itemsProvider)
          .value!
          .firstWhere((Item i) => i.id == id);

      expect(created.title, 'Levi 501');
    });
  });

  group('QuickAddScreen', () {
    testWidgets('Save is disabled until a title is typed', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const QuickAddScreen());

      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), 'Nike Air Max 90');
      await tester.pumpAndSettle();

      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNotNull,
      );
    });

    testWidgets('asks for one field and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const QuickAddScreen());

      // Hard rule 2 as a test: a second field appearing here is the change
      // that needs approval.
      expect(find.byType(SdTextFieldV3), findsOneWidget);
    });

    testWidgets('the item ceiling blocks Save with the Premium gate', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const QuickAddScreen(),
        overrides: <Override>[
          addItemBlockProvider.overrideWith((Ref ref) => PlanBlock.itemLimit),
        ],
      );

      await tester.enterText(find.byType(TextField), 'Nike Air Max 90');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to continue'), findsOneWidget);
      expect(find.textContaining('items. Upgrade'), findsOneWidget);
    });
  });
}

class _AlwaysMock extends DataModeController {
  @override
  DataMode build() => DataMode.mock;
}
