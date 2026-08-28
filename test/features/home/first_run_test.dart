import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// What Home says to an account that has just been created.
///
/// It used to say **"All clear — nothing needs your attention right now"**,
/// which is a report on work to a seller who has none, and it captioned an
/// empty gap with "Recent activity". Both read as an app that had already
/// looked at their business and found nothing worth mentioning.
void main() {
  /// A workspace with nothing in it — every source empty, not merely filtered.
  List<Override> emptyBusiness() => <Override>[
    itemsProvider.overrideWith(
      (Ref ref) => Stream<List<Item>>.value(const <Item>[]),
    ),
    ordersProvider.overrideWith(
      (Ref ref) => Stream<List<Order>>.value(const <Order>[]),
    ),
    offersProvider.overrideWith(
      (Ref ref) => Stream<List<Offer>>.value(const <Offer>[]),
    ),
  ];

  testWidgets('a business with nothing in it is told where to start', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen(), overrides: emptyBusiness());

    expect(find.text('Start here'), findsOneWidget);
    // The two must never both be offered: one says there is no work, the
    // other says the work is done.
    expect(find.text('All clear'), findsNothing);
  });

  testWidgets('a business that has started is not told to start again', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    expect(find.text('Start here'), findsNothing);
  });

  testWidgets('no orders means no Recent activity heading', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen(), overrides: emptyBusiness());

    // The heading used to render unconditionally while the section under it
    // collapsed, leaving a title over a gap.
    expect(find.text('Recent Activity'), findsNothing);
  });

  testWidgets('the heading comes back with the orders', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    // Home is a lazy list and the section sits below the fold, so the heading
    // is not built until it is scrolled to — `find.text` matches built
    // widgets only.
    for (int i = 0; i < 6 && find.text('Recent Activity').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(find.text('Recent Activity'), findsOneWidget);
  });
}
