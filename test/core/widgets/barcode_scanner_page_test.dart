import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/barcode_scanner_page.dart';

import '../../support/fakes/fake_scanner_platform.dart';
import '../../support/fixtures/sample_bottles.dart';
import '../../support/pump_app.dart';

/// Sourcing's scanner: it asks no question of the code, it hands it back to
/// the buy calculator that opened it.
void main() {
  late FakeScannerPlatform camera;
  late List<String?> answers;

  setUp(() {
    camera = FakeScannerPlatform.install();
    answers = <String?>[];
  });

  Future<void> open(WidgetTester tester) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => answers.add(
              await BarcodeScannerPage.show(
                context,
                title: 'Scan to check',
                hint: 'Point at the barcode',
              ),
            ),
            child: const Text('open', style: TextStyle()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a scanned bottle comes back as its code, once', (
    WidgetTester tester,
  ) async {
    await open(tester);

    camera.scan(SampleBottles.water.code);
    camera.scan(SampleBottles.cola.code);
    await tester.pumpAndSettle();

    expect(answers, <String?>[SampleBottles.water.code]);
    expect(find.text('Scan to check'), findsNothing);
  });

  testWidgets('backing out answers nothing', (WidgetTester tester) async {
    await open(tester);

    // The system back gesture — the app bar draws its own back button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(answers, <String?>[null]);
  });
}
