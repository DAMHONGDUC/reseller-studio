import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/more/more_constant.dart';
import 'package:reseller_studio/features/more/presentation/screens/contact_support_screen/contact_support_screen.dart';

import '../../support/pump_app.dart';

void main() {
  test('the More row opens the Contact support screen', () {
    final MoreDestination row = MoreConstant.destinations.firstWhere(
      (MoreDestination d) => d.kind == MoreDestinationKind.contactSupport,
    );

    expect(row.route, AppRoutes.contactSupport);
  });

  testWidgets('with no address configured the send button is disabled', (
    WidgetTester tester,
  ) async {
    // The suite runs with no env file, so CONTACT_EMAIL_SUPPORT is empty.
    await pumpScreen(tester, const ContactSupportScreen());

    final BuildContext context = tester.element(
      find.byType(ContactSupportScreen),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text(context.l10n.contactSupportSend), findsOneWidget);
  });
}
