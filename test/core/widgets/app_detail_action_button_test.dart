import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_detail_action_button.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('draws the more_vert glyph and keeps the label as its name', (
    WidgetTester tester,
  ) async {
    // Owner's rule: the same control the inventory row carries, and a label
    // that survives for the screen reader rather than for the bar.
    await pumpScreen(
      tester,
      AppDetailActionButton(label: 'Actions', onPressed: () {}),
    );

    final SdAppBarActionButtonV3 button = tester.widget<SdAppBarActionButtonV3>(
      find.byType(SdAppBarActionButtonV3),
    );

    expect(button.icon, AppIconConstant.moreVert);
    expect(button.tooltip, 'Actions');
    expect(find.text('Actions'), findsNothing);
  });
}
