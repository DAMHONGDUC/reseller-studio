import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_detail_action_button.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('uses medium proportions for a balanced label and icon', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      AppDetailActionButton(label: 'Actions', onPressed: () {}),
    );

    final SdButtonV3 button = tester.widget<SdButtonV3>(
      find.byType(SdButtonV3),
    );

    expect(button.size, SdButtonSizeV3.medium);
    expect(button.icon, isNotNull);
    expect(
      tester.widget<SdIconV3>(find.byType(SdIconV3)).size,
      SdIconV3.defaultSize,
    );
  });
}
