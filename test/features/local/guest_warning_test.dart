import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/local/guest_workspace_service.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_providers.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/carriers/domain/entities/carrier.dart';
import 'package:reseller_studio/features/inventory/data/repositories/local_item_repository.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/features/workspace/domain/entities/workspace.dart';
import 'package:reseller_studio/features/workspace/presentation/widgets/guest_drain_gate.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

/// **The architecture is allowed to lose a guest's records only if the
/// product says so out loud** (`docs/rules/GUEST_MODE.md`).
///
/// Deleting the app deletes a guest's business, and the owner accepted that
/// deliberately. What makes it an accepted cost rather than a trap is the
/// warning — so the warning is pinned in both directions: it appears when
/// there is something to lose, and it stays away when there is not.
///
/// Pumped through the real router rather than `pumpScreen`, for the reason
/// `guest_shell_test.dart` does: Home read through the fake store and Home
/// read through the guest store are different trees, and this is about the
/// second one.
void main() {
  const String bannerTitle = 'These records are only on this phone';

  late LocalDatabase db;
  late GoRouter router;

  Item item(String id) => Item(
    id: id,
    title: 'Item $id',
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpGuestHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': true,
    });

    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await GuestWorkspaceService(db).ensureExists(
      marketplaces: const <Marketplace>[],
      categories: const <ItemCategory>[],
      carriers: const <Carrier>[],
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
        localDatabaseProvider.overrideWithValue(db),
      ],
    );

    addTearDown(container.dispose);

    router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: AppScreenUtil(
          builder: (BuildContext context) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );

    router.go(AppRoutes.home);

    // Bounded, never `pumpAndSettle`: a guest's Home leaves a section
    // loading — there is no server to answer it — and a spinner that animates
    // forever is a settle that never returns.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  setUp(() => db = LocalDatabase.forTesting(NativeDatabase.memory()));

  tearDown(() => db.close());

  testWidgets('a guest with records is told they are only on this phone', (
    WidgetTester tester,
  ) async {
    await LocalItemRepository(db, currency: 'USD').save(item('a'));

    await pumpGuestHome(tester);

    expect(find.text(bannerTitle), findsOneWidget);
  });

  testWidgets('a guest who has entered nothing is not warned about nothing', (
    WidgetTester tester,
  ) async {
    await pumpGuestHome(tester);

    expect(find.text(bannerTitle), findsNothing);
  });

  testWidgets('the drain sheet names every business and the new one', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      // The sheet normally arrives inside a sheet route, which is what gives
      // it a Material ancestor and a bounded height. Pumped on its own it has
      // neither, so the test supplies both rather than the widget carrying
      // them for a case that never happens in the app.
      Material(
        child: SingleChildScrollView(
          child: GuestDrainSheet(
            candidates: <Workspace>[
              Workspace(
                id: 'ws-1',
                name: 'Thrift Books',
                ownerId: 'uid',
                country: 'us',
                currency: 'USD',
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ),
      ),
      overrides: <Override>[localDatabaseProvider.overrideWithValue(db)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Thrift Books'), findsOneWidget);
    // Never defaulted: creating a separate business is always on offer, so
    // the seller is never cornered into a merge.
    expect(find.text('Keep them in a new business'), findsOneWidget);
  });
}
