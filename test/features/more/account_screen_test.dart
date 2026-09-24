import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/features/more/presentation/screens/account_screen/account_screen.dart';

import '../../support/pump_app.dart';

/// Who is signed in, and the two ways out — pushed from More's Account row,
/// which never prints the email or the name itself.
void main() {
  testWidgets('falls back to "Signed in" with no name or email on file', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AccountScreen());

    final BuildContext context = tester.element(find.byType(AccountScreen));

    expect(find.text(context.l10n.settingsSignedIn), findsOneWidget);
  });

  testWidgets('offers sign out and delete account', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AccountScreen());

    final BuildContext context = tester.element(find.byType(AccountScreen));

    expect(find.text(context.l10n.settingsSignOut), findsOneWidget);
    expect(find.text(context.l10n.settingsDeleteAccount), findsOneWidget);
  });

  testWidgets('sign out asks first, naming what stays', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AccountScreen());

    final BuildContext context = tester.element(find.byType(AccountScreen));

    await tester.tap(find.text(context.l10n.settingsSignOut));
    await tester.pumpAndSettle();

    expect(find.text(context.l10n.settingsSignOutConfirmTitle), findsOneWidget);
  });

  testWidgets('delete account asks first, naming what goes', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AccountScreen());

    final BuildContext context = tester.element(find.byType(AccountScreen));

    await tester.tap(find.text(context.l10n.settingsDeleteAccount));
    await tester.pumpAndSettle();

    expect(
      find.text(context.l10n.settingsDeleteAccountConfirmTitle),
      findsOneWidget,
    );
  });
}
