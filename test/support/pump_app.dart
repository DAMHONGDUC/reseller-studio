import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/time/app_clock.dart';
import 'package:reseller_studio/features/expenses/domain/entities/expense.dart';
import 'package:reseller_studio/features/expenses/providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/mock_data/data/in_memory_repositories.dart';
import 'package:reseller_studio/features/mock_data/domain/mock_dataset.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';
import 'package:reseller_studio/features/sourcing/providers.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

/// The instant the seeded dataset is generated against in every test.
///
/// Pinned so assertions about counts are stable: the seed places rows
/// relative to "now", so a floating clock would make "listed 84 days ago"
/// drift across the stale threshold on some runs and not others.
final DateTime testNow = DateTime(2026, 8, 12);

/// A clock stopped at [testNow].
///
/// Seeding the dataset against a fixed instant is only half of it: a screen
/// that read the wall clock would still drift past those rows as the calendar
/// moves, so what a test asserts about "overdue" or "stale" would depend on
/// the day it ran. Overriding [clockProvider] pins both halves to the same
/// instant.
class FixedClock extends AppClock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}

/// Forces mock mode without touching `SharedPreferences`.
///
/// Overriding `build` rather than seeding preferences keeps the test
/// synchronous — the real controller reads an async provider, and a screen
/// pumped before it resolves would render live mode and throw.
class _AlwaysMock extends DataModeController {
  @override
  DataMode build() => DataMode.mock;
}

/// Pump a screen the way the app builds it: screenutil installed, the app
/// theme applied, localizations available, and the mock backend wired.
///
/// A test that pumps a bare `MaterialApp` is testing a tree the app never
/// builds — `context.sdTheme3` asserts without the theme extension and
/// `SdSpacingConstant` throws without screenutil.
///
/// [overrides] are appended after the mock wiring, so a test can replace one
/// provider — the inbox, say, which has no mock backend to seed — without
/// rebuilding the scope by hand.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
}) => _pumpApp(tester, overrides: overrides, home: screen);

/// Pump [screen] as a route, so a widget that calls `context.push` has a
/// router to push into. The returned router is how a test reads where it went.
///
/// Every other destination is a placeholder: what these tests assert is which
/// screen a button names, and building the real one would drag its providers
/// into a test about a tap.
Future<GoRouter> pumpRoutedScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => screen,
      ),
      GoRoute(
        // `(.*)` so one placeholder stands in for every path the screen under
        // test could push, however many segments it has.
        path: '/:destination(.*)',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );

  await _pumpApp(tester, overrides: overrides, router: router);

  return router;
}

/// The wiring both pumps share: the device surface, the mock backend, the
/// theme and the localizations.
Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Override> overrides,
  Widget? home,
  GoRouter? router,
}) async {
  // The default test surface is 800×600 — wider and much shorter than any
  // phone, which makes rows that are fine on device overflow here and hides
  // real overflows behind fake ones. Pin it to the device the layouts were
  // drawn for (iPhone 15, @3x).
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;

  // **The default test view has no notch**, so every inset bug costs exactly
  // 0 pixels here and a widget test cannot see it. Give it the device's real
  // insets: a 59pt status bar and a 34pt home indicator, in physical pixels
  // because that is what `FakeViewPadding` takes.
  tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
  tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
  addTearDown(tester.view.reset);

  const List<LocalizationsDelegate<Object>> delegates =
      <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataModeProvider.overrideWith(_AlwaysMock.new),
        clockProvider.overrideWith((Ref ref) => FixedClock(testNow)),
        mockStoreProvider.overrideWith(
          (Ref ref) => MockStore(MockDataset.seed(now: testNow)),
        ),
        ...overrides,
      ],
      child: ScreenUtilInit(
        designSize: ResellerStudioApp.designSize,
        builder: (BuildContext context, Widget? _) => router == null
            ? MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: delegates,
                home: home,
              )
            : MaterialApp.router(
                theme: AppTheme.light,
                localizationsDelegates: delegates,
                routerConfig: router,
              ),
      ),
    ),
  );

  // The repositories emit their first value on a microtask, so one pump is
  // not enough to get past the loading state.
  await tester.pumpAndSettle();
}

/// A container wired to the mock backend, for testing providers without a
/// widget tree.
ProviderContainer mockContainer() {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      dataModeProvider.overrideWith(_AlwaysMock.new),
      clockProvider.overrideWith((Ref ref) => FixedClock(testNow)),
      mockStoreProvider.overrideWith(
        (Ref ref) => MockStore(MockDataset.seed(now: testNow)),
      ),
    ],
  );

  addTearDown(container.dispose);

  return container;
}

/// Wait for every source stream's first emission.
///
/// A `StreamProvider`'s `.value` is null until it emits, and the aggregate
/// providers read `.value ?? []` — so reading a summary synchronously after
/// creating the container returns an empty one rather than the seeded
/// figures. Awaiting the `.future` of each source forces the first value
/// through.
Future<void> warmUp(ProviderContainer container) async {
  // Subscribing is what starts the generator; the aggregate providers read
  // `.value ?? []`, so without this they fold over an empty list and every
  // figure comes back null.
  //
  // Deliberately NOT `await container.read(p.future)`: the mock streams are
  // backed by a broadcast controller that never closes, and awaiting their
  // future hangs until the test times out.
  container.listen<AsyncValue<List<Item>>>(
    itemsProvider,
    (AsyncValue<List<Item>>? previous, AsyncValue<List<Item>> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<List<Order>>>(
    ordersProvider,
    (AsyncValue<List<Order>>? previous, AsyncValue<List<Order>> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<List<Expense>>>(
    expensesProvider,
    (AsyncValue<List<Expense>>? previous, AsyncValue<List<Expense>> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<List<Listing>>>(
    listingsProvider,
    (AsyncValue<List<Listing>>? previous, AsyncValue<List<Listing>> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<List<Offer>>>(
    offersProvider,
    (AsyncValue<List<Offer>>? previous, AsyncValue<List<Offer>> next) {},
    fireImmediately: true,
  );
  container.listen<AsyncValue<List<Purchase>>>(
    purchasesProvider,
    (AsyncValue<List<Purchase>>? previous, AsyncValue<List<Purchase>> next) {},
    fireImmediately: true,
  );

  // The generators yield their first value on a microtask.
  await Future<void>.delayed(Duration.zero);
}
