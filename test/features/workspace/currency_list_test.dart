import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/currency_decimals.dart';
import 'package:reseller_studio/features/workspace/currency_constant.dart';
import 'package:reseller_studio/features/workspace/currency_label.dart';
import 'package:reseller_studio/features/workspace/presentation/screens/workspace_setup_screen/workspace_setup_screen.dart';

import '../../support/pump_app.dart';

/// The currency list is as complete as the country list — owner's rule.
///
/// **Opening it was only safe because the money layer was finished first.**
/// `CurrencyDecimals` used to skip the three-decimal currencies on the
/// explicit grounds that none of them was selectable; the moment the picker
/// offered KWD, every dinar amount would have been out by a factor of ten.
void main() {
  group('the list', () {
    test('every code is a distinct three-letter ISO 4217 code', () {
      for (final String code in CurrencyConstant.codes) {
        expect(RegExp(r'^[A-Z]{3}$').hasMatch(code), isTrue, reason: code);
      }

      expect(
        CurrencyConstant.codes.toSet().length,
        CurrencyConstant.codes.length,
      );
    });

    test('it is long enough to be the real set, not a shortlist again', () {
      // The nine-entry list is what this rule replaced. A future edit that
      // trims it back to a handful fails here rather than quietly shipping.
      expect(CurrencyConstant.codes.length, greaterThan(100));
    });

    testWidgets('every code has words, and none falls back to itself', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const WorkspaceSetupScreen());

      final BuildContext context = tester.element(
        find.byType(WorkspaceSetupScreen),
      );

      for (final String code in CurrencyConstant.codes) {
        expect(
          CurrencyLabel.of(context, code),
          isNot(code),
          reason: '$code has no ARB key, so the picker would show the code',
        );
      }
    });

    testWidgets('the picker is ordered by the name a seller reads', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const WorkspaceSetupScreen());

      final BuildContext context = tester.element(
        find.byType(WorkspaceSetupScreen),
      );
      final List<String> names = CurrencyConstant.codes
          .map((String code) => CurrencyLabel.of(context, code))
          .toList();

      expect(names, orderedEquals(<String>[...names]..sort()));
    });
  });

  test('every offered currency has a decimal count the money layer knows', () {
    // The list and `CurrencyDecimals` are two files that must agree. This is
    // the cheap half: nothing in the picker may be silently taking the
    // fallback when it is a zero- or three-decimal currency.
    for (final String code in CurrencyConstant.codes) {
      expect(
        CurrencyDecimals.of(code),
        anyOf(0, 2, 3),
        reason: '$code has no sensible decimal count',
      );
    }
  });
}
