import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/title_builder_sheet.dart';

import '../../support/pump_app.dart';

/// The title builder previews the title as the parts are typed and hands it
/// back to the field that opened it.
void main() {
  testWidgets('builds a title from its parts and returns it', (
    WidgetTester tester,
  ) async {
    String? built;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => built = await TitleBuilderSheet.show(
                context,
                condition: 'Used',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Levis');
    await tester.enterText(find.byType(TextField).at(1), 'Trucker Jacket');
    await tester.pumpAndSettle();

    expect(find.text('Levis Trucker Jacket Used'), findsOneWidget);

    await tester.tap(find.text('Use this title'));
    await tester.pumpAndSettle();

    expect(built, 'Levis Trucker Jacket Used');
  });
}
