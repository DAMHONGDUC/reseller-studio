import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/time/app_clock.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/features/expenses/domain/entities/expense.dart';
import 'package:reseller_studio/features/expenses/providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/providers.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';
import 'package:reseller_studio/features/sourcing/providers.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';

import 'fakes/fake_overrides.dart';
import 'fakes/in_memory_repositories.dart';
import 'fakes/mock_dataset.dart';

/// The windows a test can pump into.
///
/// **[phone] is every test's default and must stay so.** The responsive rules
/// are a no-op at phone width by design (`docs/rules/RESPONSIVE.md`), so a
/// test written before tablets keeps asserting exactly what it asserted —
/// and a test that names a tablet is deliberately asking about the rules.
final class TestSurface {
  /// iPhone 15 — the canvas the layouts were drawn for.
  static const Size phone = Size(393, 852);

  /// iPad 11", held upright.
  static const Size tabletPortrait = Size(820, 1180);

  /// The same iPad, on its side.
  static const Size tabletLandscape = Size(1180, 820);
}

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

/// Pump a screen the way the app builds it: screenutil installed, the app
/// theme applied, localizations available, and the mock backend wired.
///
/// A test that pumps a bare `MaterialApp` is testing a tree the app never
/// builds — `context.sdTheme3` asserts without the theme extension and
/// `SdSpacingConstant` throws without screenutil.
///
/// [overrides] are appended after the fake wiring, so a test can replace one
/// provider — the inbox, say, which has no fake to seed — without rebuilding
/// the scope by hand. A provider that is ALSO in `FakeOverrides` must be named
/// in [replaces]: Riverpod throws on two overrides of one provider rather than
/// letting the later win.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
  Set<Object> replaces = const <Object>{},
  Size surface = TestSurface.phone,
  Locale? locale,
}) => _pumpApp(
  tester,
  overrides: overrides,
  replaces: replaces,
  home: screen,
  surface: surface,
  locale: locale,
);

/// Pump [screen] as a route, so a widget that calls `context.push` has a
/// router to push into. The returned router is how a test reads where it went.
///
/// Every other destination is a placeholder: what these tests assert is which
/// screen a button names, and building the real one would drag its providers
/// into a test about a tap.
///
/// [builder] is `MaterialApp.router`'s own builder — the slot the app mounts
/// its gates in, above the router's navigator. A test about one of those has
/// to pump it there, because sitting inside a route is the one place they do
/// not live.
Future<GoRouter> pumpRoutedScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
  Set<Object> replaces = const <Object>{},
  Size surface = TestSurface.phone,
  TransitionBuilder? builder,
  Locale? locale,
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

  await _pumpApp(
    tester,
    overrides: overrides,
    replaces: replaces,
    router: router,
    surface: surface,
    builder: builder,
    locale: locale,
  );

  return router;
}

/// The wiring both pumps share: the device surface, the in-memory backend,
/// the theme and the localizations.
Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Override> overrides,
  required Set<Object> replaces,
  Widget? home,
  GoRouter? router,
  Size surface = TestSurface.phone,
  TransitionBuilder? builder,
  Locale? locale,
}) async {
  // The default test surface is 800×600 — wider and much shorter than any
  // phone, which makes rows that are fine on device overflow here and hides
  // real overflows behind fake ones. Pin it to the window the test asked for,
  // which is the device the layouts were drawn for unless it said otherwise.
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = surface * 3;

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
        clockProvider.overrideWith((Ref ref) => FixedClock(testNow)),
        ...FakeOverrides.forStore(
          MockStore(MockDataset.seed(now: testNow)),
          except: replaces,
        ),
        ...overrides,
      ],
      child: AppScreenUtil(
        builder: (BuildContext context) => router == null
            ? MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: delegates,
                locale: locale,
                home: home,
              )
            : MaterialApp.router(
                theme: AppTheme.light,
                localizationsDelegates: delegates,
                locale: locale,
                routerConfig: router,
                builder: builder,
              ),
      ),
    ),
  );

  // The repositories emit their first value on a microtask, so one pump is
  // not enough to get past the loading state.
  await tester.pumpAndSettle();
}

/// A container wired to the in-memory backend, for testing providers without
/// a widget tree.
ProviderContainer mockContainer({
  List<Override> overrides = const <Override>[],
  Set<Object> replaces = const <Object>{},
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      clockProvider.overrideWith((Ref ref) => FixedClock(testNow)),
      ...FakeOverrides.forStore(
        MockStore(MockDataset.seed(now: testNow)),
        except: replaces,
      ),
      ...overrides,
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
  container.listen<AsyncValue<List<Marketplace>>>(
    marketplacesProvider,
    (
      AsyncValue<List<Marketplace>>? previous,
      AsyncValue<List<Marketplace>> next,
    ) {},
    fireImmediately: true,
  );

  // The generators yield their first value on a microtask.
  await Future<void>.delayed(Duration.zero);
}

/// Scrolls [text] into view, then returns the finder for it.
///
/// **Extracted on its second copy.** The sale picker draws the inventory card,
/// so three or four rows fill a phone screen and a `tap` on the fifth finds
/// nothing — a test that fails on layout rather than on what it is asserting.
///
/// **The list is the last scrollable, never the first.** A search field owns
/// one of its own and it comes first in the tree; dragging that scrolls
/// nothing and disposes itself mid-drag, which surfaces as `No element`.
Future<Finder> revealText(WidgetTester tester, String text) async {
  final Finder target = find.text(text);

  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();

  return target;
}
