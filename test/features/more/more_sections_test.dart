import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/more/more_constant.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';

import '../../support/pump_app.dart';

void main() {
  test('every More destination belongs to its representative section', () {
    final Map<MoreSectionKind, List<MoreDestinationKind>> actual =
        <MoreSectionKind, List<MoreDestinationKind>>{
          for (final MoreSection section in MoreConstant.sections)
            section.kind: section.destinations
                .map((MoreDestination destination) => destination.kind)
                .toList(),
        };

    expect(actual, <MoreSectionKind, List<MoreDestinationKind>>{
      MoreSectionKind.operations: <MoreDestinationKind>[
        MoreDestinationKind.sourcing,
        MoreDestinationKind.listings,
        MoreDestinationKind.categories,
        MoreDestinationKind.locations,
      ],
      MoreSectionKind.finance: <MoreDestinationKind>[
        MoreDestinationKind.expenses,
        MoreDestinationKind.payouts,
        // Close the books sits directly before the two screens that export:
        // fix the figures, then hand them over.
        MoreDestinationKind.books,
        MoreDestinationKind.reports,
        MoreDestinationKind.receipts,
        MoreDestinationKind.tax,
      ],
      MoreSectionKind.business: <MoreDestinationKind>[
        MoreDestinationKind.businesses,
        MoreDestinationKind.marketplaces,
        MoreDestinationKind.carriers,
        MoreDestinationKind.team,
        MoreDestinationKind.activity,
      ],
      MoreSectionKind.account: <MoreDestinationKind>[
        MoreDestinationKind.subscription,
        MoreDestinationKind.settings,
      ],
    });
  });

  test('the businesses row heads the Business section', () {
    final List<MoreSection> sections = MoreConstant.sectionsFor(signedIn: true);
    final MoreSection business = sections.firstWhere(
      (MoreSection section) => section.kind == MoreSectionKind.business,
    );

    // It names no record, so it is a const route rather than one built from
    // the resolved workspace id.
    expect(business.destinations.first.kind, MoreDestinationKind.businesses);
    expect(business.destinations.first.route, '/more/businesses');
  });

  test('monetisation off drops the Subscription row and nothing else', () {
    final List<MoreSection> off = MoreConstant.sectionsFor(
      signedIn: true,
      premiumEnabled: false,
    );
    final List<MoreDestinationKind> kinds = off
        .expand((MoreSection section) => section.destinations)
        .map((MoreDestination destination) => destination.kind)
        .toList();

    // A row that opens a plan screen while nothing is for sale is a row that
    // leads to an empty promise.
    expect(kinds, isNot(contains(MoreDestinationKind.subscription)));
    expect(kinds, contains(MoreDestinationKind.settings));
    expect(
      kinds.length,
      MoreConstant.sectionsFor(signedIn: true)
              .expand((MoreSection section) => section.destinations)
              .length -
          1,
    );
  });

  testWidgets('signed-in More renders every section title', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(true)],
    );

    final BuildContext context = tester.element(find.byType(MoreScreen));
    final Finder scrollable = find.byType(Scrollable).first;

    for (final MoreSection section in MoreConstant.sections) {
      final Finder title = find.text(
        MoreSectionLabel.of(context, section.kind),
      );
      await tester.scrollUntilVisible(title, 200, scrollable: scrollable);

      expect(title, findsOneWidget);
    }
  });
}
