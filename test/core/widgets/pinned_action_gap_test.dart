import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_pinned_action.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Two stacked bottom actions are one control group and have to read as a
/// pair — never as one button, which is what no gap at all looked like on the
/// two screens that forgot to draw their own.
///
/// The gap belongs to the slot, so a screen cannot get it wrong by omission.
void main() {
  /// The height of the box the slot puts between the two buttons.
  double gapBetween(WidgetTester tester) {
    final Column column = tester.widget<Column>(
      find.descendant(
        of: find.byType(AppPinnedAction),
        matching: find.byType(Column),
      ),
    );

    return tester
        .widget<SizedBox>(
          find.byWidget(
            column.children.firstWhere((Widget child) => child is SizedBox),
          ),
        )
        .height!;
  }

  testWidgets('the slot draws the gap between the two actions', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: AppPinnedAction(
          label: 'Save',
          onPressed: () {},
          secondary: SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: 'Save and add another',
            expand: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(gapBetween(tester), SdContentPaddingV3.stackedActionsGap);
  });

  testWidgets('one action alone gets no gap above it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(body: AppPinnedAction(label: 'Save', onPressed: () {})),
    );

    final Column column = tester.widget<Column>(
      find.descendant(
        of: find.byType(AppPinnedAction),
        matching: find.byType(Column),
      ),
    );

    // A slot-owned gap over a screen with no second action would be a hole
    // above the primary — which is why an absent action is null, never an
    // empty widget.
    expect(column.children.whereType<SizedBox>(), isEmpty);
  });
}
