import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/core/theme/app_theme.dart';
import 'package:seller_os/features/expenses/domain/entities/expense.dart';
import 'package:seller_os/features/expenses/providers.dart';
import 'package:seller_os/features/inventory/domain/entities/item.dart';
import 'package:seller_os/features/inventory/providers.dart';
import 'package:seller_os/features/listings/domain/entities/listing.dart';
import 'package:seller_os/features/listings/providers.dart';
import 'package:seller_os/features/mock_data/data/in_memory_repositories.dart';
import 'package:seller_os/features/mock_data/domain/mock_dataset.dart';
import 'package:seller_os/features/mock_data/providers.dart';
import 'package:seller_os/features/orders/domain/entities/order.dart';
import 'package:seller_os/features/orders/providers.dart';
import 'package:seller_os/l10n/gen/app_localizations.dart';
import 'package:seller_os/seller_os_app.dart';

/// The instant the seeded dataset is generated against in every test.
///
/// Pinned so assertions about counts are stable: the seed places rows
/// relative to "now", so a floating clock would make "listed 84 days ago"
/// drift across the stale threshold on some runs and not others.
final DateTime testNow = DateTime(2026, 8, 12);

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
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  // The default test surface is 800×600 — wider and much shorter than any
  // phone, which makes rows that are fine on device overflow here and hides
  // real overflows behind fake ones. Pin it to the device the layouts were
  // drawn for (iPhone 15, @3x).
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataModeProvider.overrideWith(_AlwaysMock.new),
        mockStoreProvider.overrideWith(
          (Ref ref) => MockStore(MockDataset.seed(now: testNow)),
        ),
      ],
      child: ScreenUtilInit(
        designSize: SellerOsApp.designSize,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: screen,
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

  // The generators yield their first value on a microtask.
  await Future<void>.delayed(Duration.zero);
}
