import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/notifications/domain/entities/notification_preferences.dart';
import 'package:reseller_studio/features/notifications/domain/enums/notification_type.dart';
import 'package:reseller_studio/features/notifications/presentation/screens/notification_settings_screen/notification_settings_screen.dart';

import '../../support/pump_app.dart';

/// Every reminder the app can send has to be turnable off on its own.
///
/// Without this screen a seller annoyed by one reminder has only the operating
/// system's switch, which takes the new-order push with it — and that is the
/// one nobody wants to lose. The list is built from the enum, so a type added
/// without a home here would fail these rather than ship unswitchable.
void main() {
  testWidgets('offers a switch for every reminder and none for unknown', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const NotificationSettingsScreen());

    expect(
      find.byType(Switch),
      findsNWidgets(NotificationType.configurable.length),
    );
    expect(
      NotificationType.configurable.contains(NotificationType.unknown),
      isFalse,
    );
  });

  testWidgets('every reminder starts on, and says what turning it off costs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const NotificationSettingsScreen());

    // Absent means on: a person who has never opened this screen must not
    // find every reminder already silenced.
    for (final Switch control in tester.widgetList<Switch>(
      find.byType(Switch),
    )) {
      expect(control.value, isTrue);
    }

    await tester.scrollUntilVisible(find.byType(Switch).last, 200);

    expect(find.textContaining('paid you for'), findsOneWidget);
  });

  group('NotificationPreferences', () {
    test('a stored mute silences exactly one type', () {
      const NotificationPreferences preferences = NotificationPreferences(
        <NotificationType>{NotificationType.staleInventory},
      );

      expect(preferences.isEnabled(NotificationType.staleInventory), isFalse);
      expect(preferences.isEnabled(NotificationType.orderCreated), isTrue);
      expect(preferences.mutedCount, 1);
    });

    test('nothing stored means everything is on', () {
      const NotificationPreferences preferences =
          NotificationPreferences.everything();

      for (final NotificationType type in NotificationType.configurable) {
        expect(preferences.isEnabled(type), isTrue);
      }
    });
  });
}
