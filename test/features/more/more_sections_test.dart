import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/more/more_constant.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';
import 'package:system_design/index.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  /// A destination's tile: the card whose semantic label is its name.
  Finder tileOf(String label) => find.byWidgetPredicate(
    (Widget widget) => widget is SdCardV3 && widget.semanticLabel == label,
  );

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
    });
  });

  test('General carries the app-level destinations, in order', () {
    expect(
      MoreConstant.general.map((MoreDestination d) => d.kind).toList(),
      <MoreDestinationKind>[
        MoreDestinationKind.subscription,
        MoreDestinationKind.notifications,
        MoreDestinationKind.about,
        MoreDestinationKind.contactSupport,
      ],
    );
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

  test('Contact support is not drawn without a configured address', () {
    // The suite runs with no env file, so CONTACT_EMAIL_SUPPORT is empty.
    final Iterable<MoreDestinationKind> kinds = MoreConstant.general
        .where((MoreDestination d) => MoreConstant.isVisible(d, true))
        .map((MoreDestination destination) => destination.kind);

    expect(kinds, contains(MoreDestinationKind.about));
    expect(kinds, isNot(contains(MoreDestinationKind.contactSupport)));
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

  testWidgets('destinations are tiles, three to a row', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(true)],
    );

    final BuildContext context = tester.element(find.byType(MoreScreen));
    final MoreSection operations = MoreConstant.sections.first;
    final List<Finder> tiles = <Finder>[
      for (final MoreDestination d in operations.destinations)
        tileOf(MoreLabel.of(context, d.kind)),
    ];

    await tester.scrollUntilVisible(
      tiles.first,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final List<Rect> rects = tiles.map(tester.getRect).toList();

    // The first three share a row; the fourth starts the next one under the
    // first, at the same width.
    expect(rects[1].top, rects[0].top);
    expect(rects[2].top, rects[0].top);
    expect(rects[3].top, greaterThan(rects[0].bottom));
    expect(rects[3].left, rects[0].left);
    expect(rects[3].width, moreOrLessEquals(rects[0].width));
  });

  testWidgets('every destination tile wears its own hue', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(true)],
    );

    final BuildContext context = tester.element(find.byType(MoreScreen));
    final MoreDestination sourcing =
        MoreConstant.sections.first.destinations.first;
    final Finder tile = tileOf(MoreLabel.of(context, sourcing.kind));

    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester
          .widget<SdIconTileV3>(
            find.descendant(of: tile, matching: find.byType(SdIconTileV3)),
          )
          .tint,
      MoreHue.of(sourcing.kind).of(context),
    );
  });

  // At a third of a phone a long label must still fit on two lines, in
  // every language the app ships — a cut-off word is a content bug.
  for (final Locale locale in ResellerStudioApp.shippingLocales) {
    testWidgets('every tile label fits — ${locale.languageCode}', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l10n = lookupAppLocalizations(locale);

      await pumpScreen(
        tester,
        const MoreScreen(),
        overrides: <Override>[isSignedInProvider.overrideWithValue(true)],
        locale: locale,
      );

      final BuildContext context = tester.element(find.byType(MoreScreen));

      for (final MoreSection section in MoreConstant.sections) {
        for (final MoreDestination d in section.destinations) {
          final String label = MoreLabel.of(context, d.kind);
          final Finder text = find.descendant(
            of: tileOf(label),
            matching: find.text(label),
          );

          await tester.scrollUntilVisible(
            text,
            200,
            scrollable: find.byType(Scrollable).first,
          );

          expect(
            (tester.renderObject(text) as RenderParagraph).didExceedMaxLines,
            isFalse,
            reason: '${l10n.localeName}: "$label"',
          );
        }
      }
    });
  }
}
