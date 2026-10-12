import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/pricing/domain/entities/pricing_rule.dart';
import 'package:reseller_studio/features/pricing/domain/enums/price_rounding.dart';
import 'package:reseller_studio/features/pricing/presentation/controllers/pricing_rule_form_controller.dart';
import 'package:reseller_studio/features/pricing/presentation/screens/pricing_rule_detail_screen/pricing_rule_detail_screen.dart';
import 'package:reseller_studio/features/pricing/presentation/screens/pricing_rules_screen/pricing_rules_screen.dart';
import 'package:reseller_studio/features/pricing/providers.dart';

import '../../support/add_button_finder.dart';
import '../../support/pump_app.dart';

/// The pricing rules screens: a rule is explained by running it, and a saved
/// rule reads back as one line.
void main() {
  testWidgets('an empty business is invited to add its first rule', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PricingRulesScreen());

    expect(find.text('No pricing rules yet'), findsOneWidget);
    expect(AddButtonFinder.named('Add pricing rule'), findsOneWidget);
  });

  testWidgets('the form previews the price a typed cost would get', (
    WidgetTester tester,
  ) async {
    final Finder empty = find.text(
      'Type a cost to see the price this rule gives.',
    );

    await pumpScreen(tester, const PricingRuleDetailScreen());
    await tester.scrollUntilVisible(
      empty,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(empty, findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '0.00').last,
      '11.70',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Lists at \$23.99'), findsOneWidget);
  });

  test('a saved rule is listed and soft-deleted, never erased', () async {
    final ProviderContainer container = mockContainer();
    final PricingRuleFormController controller = container.read(
      pricingRuleFormControllerProvider.notifier,
    );

    container.listen(pricingRulesProvider, (_, _) {}, fireImmediately: true);

    await controller.submit(
      PricingRule(
        id: 'rule-1',
        name: 'Double it',
        createdAt: DateTime(2026, 10, 11),
        multiplier: 2,
        rounding: PriceRounding.ninetyNine,
        minProfit: const Money(300, 'USD'),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activePricingRulesProvider), hasLength(1));

    await controller.delete('rule-1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activePricingRulesProvider), isEmpty);
    expect(container.read(pricingRulesProvider).value, hasLength(1));
  });

  test('a rule with no name or no multiplier is not written', () async {
    final ProviderContainer container = mockContainer();

    expect(
      await container
          .read(pricingRuleFormControllerProvider.notifier)
          .submit(
            PricingRule(id: 'r', name: ' ', createdAt: DateTime(2026, 10, 11)),
          ),
      isNull,
    );
  });
}
