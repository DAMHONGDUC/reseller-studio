import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/paywall_screen/paywall_screen.dart';
import 'package:reseller_studio/features/subscription/presentation/widgets/paywall_legal_links.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('Paywall is a bottom sheet with monthly and yearly purchase', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PaywallScreen());

    expect(find.byType(SdBottomSheetV3), findsOneWidget);
    expect(find.text('Unlock Premium'), findsOneWidget);
    expect(find.textContaining(r'$9.99 per month'), findsOneWidget);
    expect(find.textContaining(r'$89.99 per year'), findsOneWidget);
  });

  testWidgets('legal destinations are text links in one bottom row', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const PaywallLegalLinks(
        termsUrl: 'https://example.com/terms',
        privacyUrl: 'https://example.com/privacy',
      ),
    );

    expect(find.byType(Row), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Terms of Use'),
        matching: find.byType(TextButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Privacy Policy'),
        matching: find.byType(TextButton),
      ),
      findsOneWidget,
    );
  });
}
