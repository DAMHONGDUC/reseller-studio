import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/receipts/presentation/screens/receipts_screen/receipts_screen.dart';
import 'package:reseller_studio/features/reports/presentation/screens/reports_screen/reports_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('Reports keeps each stat-card row equal height', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ReportsScreen());

    final List<Size> sizes = tester
        .widgetList<SdStatTileV3>(find.byType(SdStatTileV3))
        .map((SdStatTileV3 tile) => tester.getSize(find.byWidget(tile)))
        .toList();

    expect(sizes, hasLength(4));
    expect(sizes[0].height, sizes[1].height);
    expect(sizes[2].height, sizes[3].height);
  });

  testWidgets('Receipts keeps its stat cards equal height', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ReceiptsScreen());

    final List<Size> sizes = tester
        .widgetList<SdStatTileV3>(find.byType(SdStatTileV3))
        .map((SdStatTileV3 tile) => tester.getSize(find.byWidget(tile)))
        .toList();

    expect(sizes, hasLength(2));
    expect(sizes[0].height, sizes[1].height);
  });
}
