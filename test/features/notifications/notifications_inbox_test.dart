import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/notifications/domain/entities/app_notification.dart';
import 'package:reseller_studio/features/notifications/domain/enums/notification_type.dart';
import 'package:reseller_studio/features/notifications/presentation/screens/notifications_screen/notifications_screen.dart';
import 'package:reseller_studio/features/notifications/providers.dart';

import '../../support/pump_app.dart';

/// The inbox renders its own words.
///
/// The stored document carries English text because that is what the push
/// needed and a Cloud Function cannot know the reader's locale — so the row
/// builds its line from the type and the count instead (hard rule 7). These
/// tests are what stop somebody "simplifying" that back into reading the
/// stored string.
void main() {
  AppNotification notification({
    required String id,
    required NotificationType type,
    int? count,
    DateTime? readAt,
  }) => AppNotification(
    id: id,
    type: type,
    workspaceId: 'ws-1',
    route: '/orders',
    createdAt: testNow,
    count: count,
    readAt: readAt,
  );

  List<Override> inbox(List<AppNotification> notifications) => <Override>[
    notificationsProvider.overrideWith(
      (Ref ref) => Stream<List<AppNotification>>.value(notifications),
    ),
  ];

  testWidgets('an empty inbox says so rather than rendering nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const NotificationsScreen(),
      overrides: inbox(const <AppNotification>[]),
    );

    expect(find.text('Nothing to catch up on'), findsOneWidget);
  });

  testWidgets('a digest row carries its count', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      const NotificationsScreen(),
      overrides: inbox(<AppNotification>[
        notification(
          id: 'n-1',
          type: NotificationType.shipmentsDue,
          count: 3,
        ),
        notification(id: 'n-2', type: NotificationType.staleInventory, count: 1),
      ]),
    );

    expect(find.text('3 orders are past their ship-by date'), findsOneWidget);
    // Singular, not "1 listings" — the plural form is the whole reason these
    // go through ARB rather than string concatenation.
    expect(find.text('1 listing has been up a long time'), findsOneWidget);
  });

  testWidgets('a type this build does not know still renders one line', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const NotificationsScreen(),
      overrides: inbox(<AppNotification>[
        notification(id: 'n-3', type: NotificationType.unknown),
      ]),
    );

    expect(find.text('Something happened in your business'), findsOneWidget);
  });

  testWidgets('mark all read is offered while something is unread', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const NotificationsScreen(),
      overrides: inbox(<AppNotification>[
        notification(id: 'n-4', type: NotificationType.orderCreated),
      ]),
    );

    expect(find.byTooltip('Mark all read'), findsOneWidget);
  });

  testWidgets('and not once everything is read', (WidgetTester tester) async {
    // A control that would do nothing is worse than no control.
    await pumpScreen(
      tester,
      const NotificationsScreen(),
      overrides: inbox(<AppNotification>[
        notification(
          id: 'n-5',
          type: NotificationType.orderCreated,
          readAt: testNow,
        ),
      ]),
    );

    expect(find.byTooltip('Mark all read'), findsNothing);
  });
}
