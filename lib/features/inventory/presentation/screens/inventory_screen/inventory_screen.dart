import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/providers.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/storage_location.dart';
import '../../../providers.dart';
import '../../controllers/item_actions_controller.dart';
import '../../widgets/item_actions_sheet.dart';
import '../../widgets/item_card.dart';
import '../../widgets/reprice_sheet.dart';

part 'inventory_screen_bulk_bar.dart';
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
///
/// **Long-press starts a bulk selection** (hard rule 16). While one is open
/// the Quick Add button is replaced by the action bar: two floating controls
/// competing for one corner is how the wrong one gets tapped.
///
/// This is the reference implementation of the create button every other
/// screen copies — see `AppAddFabScaffold` and the owner's rule in
/// `CLAUDE.md`.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Opens the create flow, or explains why it cannot.
  ///
  /// **Checked before the form opens, never after the seller has typed.**
  /// Refusing a title someone has already entered is the worst moment to
  /// mention a plan limit, and it loses their work.
  Future<void> _add(String route) async {
    final PlanBlock block = ref.read(addItemBlockProvider);

    if (block == PlanBlock.none) {
      unawaited(context.push(route));

      return;
    }

    await PlanBlockSheet.show(
      context,
      block: block,
      plan: ref.read(currentPlanProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> items = ref.watch(visibleItemsProvider);
    final AsyncValue<List<Item>> source = ref.watch(itemsProvider);
    final bool isSelecting = ref.watch(inventorySelectionProvider).isNotEmpty;

    return AppAddFabScaffold(
      addLabel: context.l10n.quickAddTitle,
      onAdd: () => _add(AppRoutes.quickAdd),
      floatingNav: true,
      showAdd: !isSelecting,
      bottomNavigationBar: isSelecting ? const _BulkActionBar() : null,
      // No `appBar`: `SdSearchHeaderV3` is a sliver and has to live in the
      // scroll view to dock into the title's row as the list moves.
      body: CustomScrollView(
        slivers: <Widget>[
          SdSearchHeaderV3(
            title: context.l10n.navInventory,
            controller: _search,
            hint: context.l10n.inventorySearchHint,
            clearTooltip: context.l10n.inventoryClearSearch,
            onChanged: (String value) =>
                ref.read(inventorySearchProvider.notifier).update(value),
            actions: <SdAppBarActionV3>[
              SdAppBarActionV3(
                icon: Symbols.add_box_rounded,
                tooltip: context.l10n.inventoryAddItem,
                onPressed: () => _add(AppRoutes.addItem),
              ),
              SdAppBarActionV3(
                icon: Symbols.qr_code_scanner_rounded,
                tooltip: context.l10n.inventoryScan,
                onPressed: () => context.push(AppRoutes.scanner),
              ),
            ],
          ),
          // Pinned, so the chips stay reachable 300 rows down — and still
          // not part of the app bar (owner's rules, both). The band carries
          // its own topGap above and below, so the screen places neither.
          const SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedFilterStrip(),
          ),
          switch (source) {
            // A screen that has not loaded is not empty — saying "No items"
            // to a seller with four hundred is worse than a spinner.
            AsyncLoading<List<Item>>() when !source.hasValue =>
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SdLoadingV3Page(),
              ),
            AsyncError<List<Item>>() => SliverFillRemaining(
              hasScrollBody: false,
              child: SdEmptyStateV3(
                icon: Symbols.error_rounded,
                title: context.l10n.inventoryLoadFailed,
                message: context.l10n.commonCouldNotLoad,
              ),
            ),
            _ when items.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: AppListEmptyState(
                hasAny: (source.value ?? const <Item>[]).isNotEmpty,
                noMatchMessage: context.l10n.inventoryNoMatch,
                emptyIcon: Symbols.inventory_2_rounded,
                emptyTitle: context.l10n.inventoryEmptyTitle,
                emptyMessage: context.l10n.inventoryEmptyBody,
                // The FAB says the same thing, and it is the wrong place to
                // find it: on the first empty screen a seller ever sees, the
                // eye is in the middle, not the corner.
                emptyAction: SdButtonV3(
                  variant: SdButtonVariantV3.primary,
                  label: context.l10n.quickAddTitle,
                  onPressed: () => _add(AppRoutes.quickAdd),
                ),
              ),
            ),
            _ => _ItemList(items: items),
          },
        ],
      ),
    );
  }
}
