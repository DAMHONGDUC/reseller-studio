import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_editable_section.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **A heading inside something that already carries the gutter is flush with
/// it** — owner's rule, and the reason `SdSectionHeaderV3` takes a `gutter`
/// flag rather than a padding.
///
/// The heading and the card under it sit in the same block, so a heading set
/// 16 further in than its own card reads as a stray indent. What the flag
/// must NOT drop is the vertical rhythm: a flush heading still sits the same
/// distance from the group above it as every other heading on the screen.
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

  testWidgets('dropping the gutter keeps the gap above the heading', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const Column(
        children: <Widget>[
          SdSectionHeaderV3(title: 'With gutter'),
          SdSectionHeaderV3(title: 'Flush', gutter: false),
        ],
      ),
    );

    final Size withGutter = tester.getSize(
      find.ancestor(
        of: find.text('With gutter'),
        matching: find.byType(Padding),
      ).first,
    );
    final Size flush = tester.getSize(
      find.ancestor(
        of: find.text('Flush'),
        matching: find.byType(Padding),
      ).first,
    );

    expect(flush.height, withGutter.height);
  });
}
