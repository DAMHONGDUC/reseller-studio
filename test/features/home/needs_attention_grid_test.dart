import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/time/app_clock.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';
import 'premium_subscription.dart';

/// Needs Attention is a grid of tiles with the count set large
/// (`lib/features/home/CLAUDE.md`).
void main() {
  /// A tile is the card whose semantic label is "<label>: <count>".
  Finder tileFor(String label) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is SdCardV3 &&
        (widget.semanticLabel?.startsWith('$label: ') ?? false),
  );

  testWidgets('tiles sit two across', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final List<Rect> tiles = tester
        .widgetList<SdCardV3>(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is SdCardV3 &&
                (widget.semanticLabel?.contains(': ') ?? false),
          ),
        )
        .map((SdCardV3 card) => tester.getRect(find.byWidget(card)))
        .toList();

    expect(tiles.length, greaterThanOrEqualTo(2), reason: 'seed has work');
    // The first pair shares a row: same top, side by side, equal widths.
    expect(tiles[0].top, tiles[1].top);
    expect(tiles[1].left, greaterThan(tiles[0].right));
    expect(tiles[0].width, moreOrLessEquals(tiles[1].width));
  });

  testWidgets('the count is the loudest text on a tile', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final Finder tile = tileFor('Orders to ship');
    final Text label = tester.widget<Text>(
      find.descendant(of: tile, matching: find.text('Orders to ship')),
    );
    final Text count = tester
        .widgetList<Text>(
          find.descendant(of: tile, matching: find.byType(Text)),
        )
        .firstWhere((Text text) => int.tryParse(text.data ?? '') != null);

    expect(count.style!.fontSize, greaterThan(label.style!.fontSize!));
  });

  testWidgets('an overdue order gives its tile a tinted edge', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final DateTime now = container.read(clockProvider).now();
    final bool anyOverdue = container
        .read(ordersNeedingActionProvider)
        .any((Order order) => order.isOverdue(now) ?? false);
    final SdCardV3 card = tester.widget<SdCardV3>(tileFor('Orders to ship'));

    expect(anyOverdue, isTrue, reason: 'the seed has a late order');
    expect(
      card.borderColor,
      tester.element(find.byType(HomeScreen)).sdTheme3.danger,
    );
  });
}
