import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/workspace/presentation/screens/workspace_detail_screen/workspace_detail_screen.dart';

import '../../support/pump_app.dart';

/// The other half of the same bug the item form had.
///
/// Both forms seed from a record that arrives on a stream, both learned it in
/// a `build`, and both wrote a provider from there — which throws. See
/// `FormSeed`, and `test/features/inventory/item_form_seed_test.dart`.
void main() {
  testWidgets('the business form fills in without throwing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const WorkspaceDetailScreen(workspaceId: 'ws-demo'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Attic Finds Co.'), findsWidgets);
  });

  testWidgets('the currency it was saved with is the one shown', (
    WidgetTester tester,
  ) async {
    // Read off the form's provider, so it is only right once the deferred
    // seed has landed — and it is now a name from the full ISO 4217 list.
    await pumpScreen(
      tester,
      const WorkspaceDetailScreen(workspaceId: 'ws-demo'),
    );

    expect(find.text('US Dollar'), findsOneWidget);
  });
}
