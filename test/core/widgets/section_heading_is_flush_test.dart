import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_editable_section.dart';
import 'package:reseller_studio/core/widgets/app_section.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **A section heading sits on its card's left edge, and a fixed gap holds it
/// off that card** — owner's rule (`docs/rules/DESIGN_SYSTEM.md`).
///
/// The heading carries no gutter of its own, so it can never be set further
/// in than the card it heads, whichever list it is placed in.
void main() {
  testWidgets('an editable section heads its card at the same left edge', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      AppEditableSection(
        title: 'Pricing',
        isEditing: false,
        onEdit: () {},
        onCancel: () {},
        onSave: () {},
        child: const SdCardV3(child: Text('Cost', style: TextStyle())),
      ),
    );

    final double heading = tester.getTopLeft(find.text('Pricing')).dx;
    final double card = tester.getTopLeft(find.byType(SdCardV3)).dx;

    expect(heading, card);
  });

  testWidgets('in a list that holds the gutter, heading and card share it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ListView(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        children: const <Widget>[
          SdSectionHeaderV3(title: 'Usage'),
          SdCardV3(child: Text('Items', style: TextStyle())),
        ],
      ),
    );

    final Rect heading = tester.getRect(find.byType(SdSectionHeaderV3));
    final Rect card = tester.getRect(find.byType(SdCardV3));

    expect(tester.getTopLeft(find.text('Usage')).dx, card.left);
    expect(
      card.top - tester.getBottomLeft(find.text('Usage')).dy,
      closeTo(SdContentPaddingV3.sectionHeader().bottom, 0.001),
    );
    expect(heading.bottom, card.top);
  });

  testWidgets('AppSection heads its card on the same edge, a token apart', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const AppSection(
        title: 'Overview',
        child: Text('Revenue', style: TextStyle()),
      ),
    );

    final Rect card = tester.getRect(find.byType(SdCardV3));

    expect(tester.getTopLeft(find.text('Overview')).dx, card.left);
    expect(
      card.top - tester.getBottomLeft(find.text('Overview')).dy,
      closeTo(SdContentPaddingV3.sectionHeader().bottom, 0.001),
    );
  });
}
