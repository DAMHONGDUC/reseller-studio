import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/features/sync/domain/enums/sync_status.dart';
import 'package:reseller_studio/features/sync/providers.dart';

import '../../support/pump_app.dart';

/// The card heading More says whether this device's records reached the server.
void main() {
  testWidgets('a guest is told the records are on this device only', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const MoreScreen());

    expect(find.text('Saved on this device only'), findsOneWidget);
  });

  for (final (SyncStatus status, String title) in <(SyncStatus, String)>[
    (SyncStatus.synced, 'All changes synced'),
    (SyncStatus.syncing, 'Syncing changes…'),
  ]) {
    testWidgets('an account shows ${status.name}', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        const MoreScreen(),
        overrides: <Override>[
          syncStatusProvider.overrideWith(
            (Ref ref) => Stream<SyncStatus>.value(status),
          ),
        ],
      );

      expect(find.text(title), findsOneWidget);
    });
  }
}
