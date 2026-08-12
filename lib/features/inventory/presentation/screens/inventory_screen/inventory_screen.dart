import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../domain/entities/item.dart';
import '../../../providers.dart';
import '../../widgets/item_card.dart';

part 'inventory_screen_empty_inventory.dart';
part 'inventory_screen_filter_strip.dart';
part 'inventory_screen_item_list.dart';

/// Inventory — "what do I have?".
///
/// The five tabs are fixed by the plan (§7): `All | Listed | Reserved | Sold |
/// Stale`. Each carries its count, because a seller scanning the strip decides
/// where to tap from the number — which is why `SdFilterChipV3` renders the
/// count inside the chip rather than beside it.
///
/// **All five counts come from one stream**, folded in
/// `inventoryCountsProvider`. Per-tab queries would mean five live listeners
/// for one screen, and the counts could disagree with the list being shown.
///
/// **The chrome collapses as the list scrolls.** `SdSearchHeaderV3` docks the
/// search field into the title's row and pins the filter strip under it, so a
/// seller 300 rows down still has search, filters and the scanner without
/// scrolling back to the top — and pays one bar of height for them instead of
/// three. The screen owns the controller for the same reason: the field is
/// inside a sliver that rebuilds on every scroll frame, and a controller
/// created there would be a new one each time.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _search = TextEditingController();

  /// Whether Quick Add shows its label. A notifier rather than `setState`:
  /// the direction of a scroll changes several times a second, and rebuilding
  /// the whole list for the width of a button is exactly the cost this screen
  /// cannot pay.
  final ValueNotifier<bool> _quickAddExpanded = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _search.dispose();
    _quickAddExpanded.dispose();
    super.dispose();
  }

  /// Collapses the button while the list is moving away under the thumb, and
  /// brings the label back the moment it stops or reverses. `idle` counts as
  /// expanded — a seller who has stopped scrolling is a seller reading, and
  /// that is when they decide to add something.
  ///
  /// Vertical only: the filter strip is a horizontal `ListView` inside the
  /// header, and swiping to reach "Stale" is not a reason to shrink the
  /// button.
  bool _onUserScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    _quickAddExpanded.value = notification.direction != ScrollDirection.reverse;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> items = ref.watch(visibleItemsProvider);
    final AsyncValue<List<Item>> source = ref.watch(itemsProvider);

    return SdScaffoldV3(
      // Lifted clear of the floating tab bar. `extendBody` keeps the FAB in
      // the body's coordinate space rather than stacking it above the bottom
      // slot, so without this the button renders *behind* the glass — which
      // looks like a bug and makes it hard to tap.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: SdContentPaddingV3.floatingBarInset(context),
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: _quickAddExpanded,
          builder: (BuildContext context, bool expanded, Widget? _) => SdFabV3(
            icon: Symbols.add_rounded,
            label: context.l10n.quickAddTitle,
            expanded: expanded,
            onPressed: () => context.push(AppRoutes.quickAdd),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onUserScroll,
        child: CustomScrollView(
          slivers: <Widget>[
            SdSearchHeaderV3(
              title: 'Inventory',
              controller: _search,
              hint: 'Title, SKU or barcode',
              clearTooltip: 'Clear search',
              onChanged: (String value) =>
                  ref.read(inventorySearchProvider.notifier).update(value),
              actions: <SdAppBarActionV3>[
                SdAppBarActionV3(
                  icon: Symbols.qr_code_scanner_rounded,
                  tooltip: 'Scan',
                  onPressed: () {},
                ),
              ],
            ),
            // The filter strip is never part of the app bar (owner's rule):
            // its own widget in the body, one topGap below the chrome.
            SliverToBoxAdapter(
              child: SizedBox(height: SdContentPaddingV3.topGap),
            ),
            const SliverToBoxAdapter(child: _FilterStrip()),
            switch (source) {
              // A screen that has not loaded is not empty — saying "No items"
              // to a seller with four hundred is worse than a spinner.
              AsyncLoading<List<Item>>() when !source.hasValue =>
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SdLoadingV3Page(),
                ),
              AsyncError<List<Item>>() => const SliverFillRemaining(
                hasScrollBody: false,
                child: SdEmptyStateV3(
                  icon: Symbols.error_rounded,
                  title: 'Could not load inventory',
                  message: 'Please try again.',
                ),
              ),
              _ when items.isEmpty => SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyInventory(
                  hasAnyItems: (source.value ?? const <Item>[]).isNotEmpty,
                ),
              ),
              _ => _ItemList(items: items),
            },
          ],
        ),
      ),
    );
  }
}
