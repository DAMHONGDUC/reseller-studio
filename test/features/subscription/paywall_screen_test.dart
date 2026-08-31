import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/subscription/data/repositories/unconfigured_subscription_repository.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';
import 'package:reseller_studio/features/subscription/domain/entities/subscription_status.dart';
import 'package:reseller_studio/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/paywall_screen/paywall_screen.dart';
import 'package:reseller_studio/features/subscription/presentation/widgets/paywall_footer_links.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// A store that will not say what it sells — the case the old paywall could
/// not tell apart from a store selling nothing.
class _SilentStore implements SubscriptionRepository {
  @override
  Stream<SubscriptionStatus> watchStatus() =>
      Stream<SubscriptionStatus>.value(SubscriptionStatus.free);

  @override
  Future<List<PlanOffering>> offerings() async =>
      throw const AppFailure(AppFailureKind.offline);

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async =>
      SubscriptionStatus.free;

  @override
  Future<SubscriptionStatus> restore() async => SubscriptionStatus.free;

  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> forget() async {}
}

void main() {
  SdCardV3 cardBehind(WidgetTester tester, String label) =>
      tester.widget<SdCardV3>(
        find
            .ancestor(of: find.text(label), matching: find.byType(SdCardV3))
            .first,
      );

  testWidgets('Paywall is a bottom sheet selling one plan on two periods', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    expect(find.byType(SdBottomSheetV3), findsOneWidget);
    expect(find.text('Unlock Premium'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text(r'$89.99'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('Start your 1 week free trial'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Yearly')).dx,
      lessThan(tester.getTopLeft(find.text('Monthly')).dx),
      reason: 'the recommended option leads, whatever order the store used',
    );
  });

  testWidgets('the yearly trial is named on the card, the button and the fine '
      'print', (WidgetTester tester) async {
    await pumpScreen(tester, const PaywallScreen());

    // Guideline 3.1.2 wants the duration and the renewing price in the
    // binary, so a badge on the card is not on its own enough.
    expect(find.text('1 week free'), findsOneWidget);
    expect(find.text('Start your 1 week free trial'), findsOneWidget);
    expect(
      find.text(
        r'Free for 1 week, then $89.99 per year. Cancel before it ends and '
        'you are not charged.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('monthly carries no trial, and picking it says so', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    // The trial is configured on the yearly product alone, so promising one
    // here would be a claim the receipt contradicts.
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('free trial'), findsNothing);
    expect(find.textContaining('Free for'), findsNothing);
  });

  testWidgets('the yearly option opens selected and is marked best value', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    expect(find.text('Best value'), findsOneWidget);
    expect(cardBehind(tester, 'Yearly').borderColor, isNotNull);
    expect(cardBehind(tester, 'Monthly').borderColor, isNull);
  });

  testWidgets('picking the other period moves the selection', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    expect(cardBehind(tester, 'Monthly').borderColor, isNotNull);
    expect(cardBehind(tester, 'Yearly').borderColor, isNull);
  });

  testWidgets('switching period leaves the prices where they were', (
    WidgetTester tester,
  ) async {
    Rect yearlyCard() => tester.getRect(
      find
          .ancestor(of: find.text('Yearly'), matching: find.byType(SdCardV3))
          .first,
    );

    await pumpScreen(tester, const PaywallScreen());

    final Rect before = yearlyCard();

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    // Only the yearly product carries a trial, and its terms sit in the
    // bottom-anchored fine print — a line that came and went with the tap
    // dragged the cards up and down the sheet.
    expect(yearlyCard(), before);
  });

  testWidgets('what Premium includes is framed as a well', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    expect(cardBehind(tester, 'Unlimited items').layer, SdCardLayerV3.sunken);
    expect(cardBehind(tester, 'Yearly').layer, SdCardLayerV3.elevated);
  });

  testWidgets('the prices and the fine print sit against the footer', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    final Rect benefits = tester.getRect(
      find
          .ancestor(
            of: find.text('Unlimited items'),
            matching: find.byType(SdCardV3),
          )
          .first,
    );
    final Rect options = tester.getRect(
      find
          .ancestor(of: find.text('Yearly'), matching: find.byType(SdCardV3))
          .first,
    );
    final Rect terms = tester.getRect(
      find.textContaining('Renews automatically'),
    );
    final Rect footer = tester.getRect(find.byType(PaywallFooterLinks));

    expect(
      footer.top - terms.bottom,
      lessThan(options.top - benefits.bottom),
      reason:
          'the slack belongs between the two halves, not under the last line',
    );
  });

  testWidgets('the sheet keeps nine tenths of the screen, footer at its foot', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    final SdBottomSheetV3 sheet = tester.widget<SdBottomSheetV3>(
      find.byType(SdBottomSheetV3),
    );
    final Rect box = tester.getRect(find.byType(SdBottomSheetV3));
    final Rect footer = tester.getRect(find.byType(PaywallFooterLinks));
    final Rect content = tester.getRect(find.byType(SingleChildScrollView));

    // The fraction itself only bites under the modal route's loose
    // constraints; here the sheet is pumped as a screen, so what is checked is
    // that it asks for one and that the content still gives the footer the
    // bottom edge.
    expect(sheet.heightFactor, PaywallScreen.heightFactor);
    expect(footer.top, greaterThanOrEqualTo(content.bottom));
    expect(box.bottom - footer.bottom, lessThan(footer.height));
  });

  testWidgets('the footer is one row of links, below the scrolling content', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    expect(find.byType(PaywallFooterLinks), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Restore purchases'),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
      reason: 'restore belongs to the fixed footer, not scrolling content',
    );
  });

  testWidgets('a store that fails offers a retry, not an empty sheet', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const PaywallScreen(),
      overrides: <Override>[
        subscriptionRepositoryProvider.overrideWithValue(_SilentStore()),
      ],
    );

    expect(find.text('Could not load the plans.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('a build without billing says so instead of offering nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const PaywallScreen(),
      overrides: <Override>[
        subscriptionRepositoryProvider.overrideWithValue(
          UnconfiguredSubscriptionRepository(),
        ),
      ],
    );

    expect(
      find.text('Purchases are not available in this build yet.'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('restore and both legal destinations share one link row', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      PaywallFooterLinks(
        termsUrl: 'https://example.com/terms',
        privacyUrl: 'https://example.com/privacy',
        onRestore: () {},
      ),
    );

    expect(find.byType(PaywallFooterLink), findsNWidgets(3));
    expect(find.byType(PaywallFooterDot), findsNWidgets(2));
    for (final String label in <String>[
      'Restore purchases',
      'Terms of Use',
      'Privacy Policy',
    ]) {
      expect(
        tester.widget<Text>(find.text(label)).style?.decoration,
        TextDecoration.underline,
      );
    }
  });
}
