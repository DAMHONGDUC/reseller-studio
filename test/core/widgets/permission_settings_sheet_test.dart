import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/permissions/app_permission.dart';
import 'package:reseller_studio/core/providers/system_permissions_provider.dart';
import 'package:reseller_studio/core/widgets/permission_settings_sheet.dart';
import 'package:reseller_studio/features/notifications/presentation/screens/notification_settings_screen/notification_settings_screen.dart';

import '../../support/fakes/fake_system_permissions.dart';
import '../../support/pump_app.dart';

/// Once the system stops asking for a permission, the only way back is the
/// app's page in Settings — so the app says what is off and opens it.
void main() {
  testWidgets('names what is off and opens Settings', (
    WidgetTester tester,
  ) async {
    final FakeSystemPermissions permissions = FakeSystemPermissions();

    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => PermissionSettingsSheet.show(
              context,
              permission: AppPermission.camera,
            ),
            child: const Text('open', style: TextStyle()),
          ),
        ),
      ),
      overrides: [systemPermissionsProvider.overrideWithValue(permissions)],
      replaces: <Object>{systemPermissionsProvider},
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Camera access is off'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(permissions.settingsOpened, 1);
    expect(find.text('Camera access is off'), findsNothing);
  });

  testWidgets('Notification settings says when the system has them off', (
    WidgetTester tester,
  ) async {
    final FakeSystemPermissions permissions = FakeSystemPermissions(
      blocked: <AppPermission>{AppPermission.notifications},
    );

    await pumpScreen(
      tester,
      const NotificationSettingsScreen(),
      overrides: [systemPermissionsProvider.overrideWithValue(permissions)],
      replaces: <Object>{systemPermissionsProvider},
    );

    await tester.tap(find.text('Notifications are off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(permissions.settingsOpened, 1);
  });

  testWidgets('no card while the system allows notifications', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const NotificationSettingsScreen());

    expect(find.text('Notifications are off'), findsNothing);
  });
}
