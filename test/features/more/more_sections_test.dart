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
        MoreDestinationKind.reports,
        MoreDestinationKind.receipts,
        MoreDestinationKind.tax,
      ],
      MoreSectionKind.business: <MoreDestinationKind>[
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

  test(
    'the business row heads the Business section when a workspace is set',
    () {
      final List<MoreSection> sections = MoreConstant.sectionsFor(
        signedIn: true,
        workspaceId: 'ws-1',
      );
      final MoreSection business = sections.firstWhere(
        (MoreSection section) => section.kind == MoreSectionKind.business,
      );

      expect(business.destinations.first.kind, MoreDestinationKind.business);
      expect(business.destinations.first.route, '/workspace/ws-1');
    },
  );

  test('no workspace, no business row — the screen behind it needs an id', () {
    final List<MoreSection> sections = MoreConstant.sectionsFor(signedIn: true);

    expect(
      sections
          .expand((MoreSection section) => section.destinations)
          .map((MoreDestination destination) => destination.kind),
      isNot(contains(MoreDestinationKind.business)),
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
