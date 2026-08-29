import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/price_entry_sheet.dart';
import '../../../domain/entities/listing.dart';
import '../../../domain/enums/listing_status.dart';
import '../../../listing_label.dart';
import '../../../providers.dart';
import '../../controllers/listing_actions_controller.dart';

part 'listings_screen_bulk_bar.dart';

/// Listings — everything live, everywhere (plan §12).
///
/// Tabs are `All | Draft | Active | Paused | Ended`, and **`error` is folded
/// into neither `ended` nor `active`**: a listing the platform rejected needs
/// the seller to do something, and burying it in a generic "ended" is how a
/// policy strike goes unnoticed. It gets its own tone and its message is shown
/// on the row.
///
/// **Rows are selectable, because §12's list is bulk work**: bulk price
/// update, bulk listing, listing history. A seller clearing stale stock cuts
/// the price on a screenful at once, and hard rule 16 says that is a
/// first-class requirement rather than a later nicety — the same selection
/// behaviour Inventory has, from the same `SelectionController`.
///
/// **Nothing here reaches a marketplace.** No integration exists (hard rule
/// 10), so a bulk change edits what Reseller Studio records; the day eBay is
/// connected, the push is a Cloud Function reading these documents.
class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  late final ListingSelectionController _selectionController;

  /// Null is the "All" tab. A nullable selection rather than a sixth enum
  /// case, so the filter is the status itself and nothing has to translate.
  ListingStatus? _filter;

  @override
  void initState() {
    super.initState();
    _selectionController = ref.read(listingSelectionProvider.notifier);
  }

  /// Leaving the screen must not leave rows ticked behind it: the selection
  /// lives in a provider, which outlives this `State`.
  @override
  void dispose() {
    // Scheduled rather than called: disposing a widget mid-frame cannot write
    // to a provider that other widgets are still building against.
    Future<void>.microtask(_selectionController.clear);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Listing>> source = ref.watch(listingsProvider);
    final List<Listing> all = source.value ?? const <Listing>[];
    final List<Listing> listings = _filter == null
        ? all
        : all.where((Listing listing) => listing.status == _filter).toList();
    final DateTime now = ref.watch(clockProvider).now();
    final Set<String> selected = ref.watch(listingSelectionProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.itemListings),
      // The bar takes the bottom slot only while something is ticked, so a
      // screen nobody is bulk-editing looks exactly as it did.
      bottomNavigationBar: selected.isEmpty ? null : const _ListingBulkBar(),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          AppFilterStrip(
            children: <Widget>[
              _StatusChip(
                label: context.l10n.commonAll,
                count: all.length,
                selected: _filter == null,
                onSelected: () => setState(() => _filter = null),
              ),
              for (final ListingStatus status in ListingStatus.values)
                _StatusChip(
                  label: ListingStatusLabel.of(context, status),
                  count: all
                      .where((Listing listing) => listing.status == status)
                      .length,
                  selected: _filter == status,
                  onSelected: () => setState(() => _filter = status),
                ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.topGap),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Listing>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              _ when listings.isEmpty => AppListEmptyState(
                hasAny: all.isNotEmpty,
                noMatchMessage: context.l10n.listingsNoMatch,
                emptyIcon: AppIconConstant.sell,
                emptyTitle: context.l10n.listingsEmptyTitle,
                emptyMessage: context.l10n.listingsListAnItemFromItsDetail,
                // Listing happens on an item, so the way on is inventory.
                emptyAction: SdButtonV3(
                  variant: SdButtonVariantV3.primary,
                  label: context.l10n.commonGoToInventory,
                  onPressed: () => context.go(AppRoutes.inventory),
                ),
              ),
              _ => ListView(
                padding: SdContentPaddingV3.screen(context),
                children: <Widget>[
                  AppListCard(
                    children: listings
                        .map(
                          (Listing listing) => _ListingRow(
                            listing: listing,
                            subtitle: _subtitle(context, listing, now),
                            tint: _tint(context, listing.status),
                            isSelected: selected.contains(listing.id),
                            // While a selection is open every tap ticks a row.
                            // A screen where tapping sometimes navigates and
                            // sometimes selects is one that loses the
                            // selection to a mis-tap.
                            isSelecting: selected.isNotEmpty,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }

  /// The platform's own rejection message is surfaced deliberately: it is the
  /// seller's action item, not the kind of internal error hard rule 6 forbids.
  static String _subtitle(BuildContext context, Listing listing, DateTime now) {
    if (listing.lastError != null) {
      return '${listing.marketplace.displayName} · ${listing.lastError}';
    }

    final int? days = listing.daysLive(now);

    return <String>[
      listing.marketplace.displayName,
      ListingStatusLabel.of(context, listing.status),
      if (days != null) context.l10n.listingDaysLive(days),
      if (listing.viewCount != null)
        context.l10n.listingViewCount(listing.viewCount!),
    ].join(' · ');
  }

  static Color _tint(BuildContext context, ListingStatus status) =>
      switch (status) {
        ListingStatus.error => context.sdTheme3.danger,
        ListingStatus.active => context.sdTheme3.success,
        ListingStatus.paused => context.sdTheme3.warning,
        ListingStatus.draft ||
        ListingStatus.ended ||
        ListingStatus.sold => context.sdTheme3.textSecondary,
      };
}

/// One listing, tickable.
///
/// **Long-press starts a selection, tap continues it** — the gesture pair
/// Inventory uses, so a seller who learned it on one screen has it on both.
class _ListingRow extends ConsumerWidget {
  const _ListingRow({
    required this.listing,
    required this.subtitle,
    required this.tint,
    required this.isSelected,
    required this.isSelecting,
  });

  final Listing listing;
  final String subtitle;
  final Color tint;
  final bool isSelected;
  final bool isSelecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ListingSelectionController selection = ref.read(
      listingSelectionProvider.notifier,
    );

    return AppListRow(
      title: listing.title,
      subtitle: subtitle,
      icon: isSelected ? AppIconConstant.checkCircle : AppIconConstant.sell,
      iconTint: isSelected ? context.colorScheme3.primary : tint,
      trailingText: context.money(listing.price),
      showChevron: !isSelecting,
      onTap: () => isSelecting
          ? selection.toggle(listing.id)
          : context.push(AppRoutes.item(listing.itemId)),
      onLongPress: () => selection.toggle(listing.id),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => SdFilterChipV3(
    label: label,
    count: count,
    selected: selected,
    onSelected: onSelected,
  );
}
