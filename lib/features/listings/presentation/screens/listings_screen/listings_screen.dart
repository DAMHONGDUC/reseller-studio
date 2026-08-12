import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/listing.dart';
import '../../../domain/enums/listing_status.dart';
import '../../../providers.dart';

/// Listings — everything live, everywhere (plan §12).
///
/// Tabs are `All | Draft | Active | Paused | Ended`, and **`error` is folded
/// into neither `ended` nor `active`**: a listing the platform rejected needs
/// the seller to do something, and burying it in a generic "ended" is how a
/// policy strike goes unnoticed. It gets its own tone and its message is shown
/// on the row.
class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  /// Null is the "All" tab. A nullable selection rather than a sixth enum
  /// case, so the filter is the status itself and nothing has to translate.
  ListingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Listing>> source = ref.watch(listingsProvider);
    final List<Listing> all = source.value ?? const <Listing>[];
    final List<Listing> listings = _filter == null
        ? all
        : all.where((Listing listing) => listing.status == _filter).toList();
    final DateTime now = DateTime.now();

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Listings'),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SizedBox(
            height: SdContentPaddingV3.filterStrip,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
                vertical: SdContentPaddingV3.filterStripGap,
              ),
              children: <Widget>[
                _StatusChip(
                  label: 'All',
                  count: all.length,
                  selected: _filter == null,
                  onSelected: () => setState(() => _filter = null),
                ),
                for (final ListingStatus status in ListingStatus.values) ...[
                  SizedBox(width: SdSpacingConstant.w8),
                  _StatusChip(
                    label: ListingStatusLabel.of(status),
                    count: all
                        .where((Listing listing) => listing.status == status)
                        .length,
                    selected: _filter == status,
                    onSelected: () => setState(() => _filter = status),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Listing>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              _ when listings.isEmpty => const SdEmptyStateV3(
                icon: Symbols.sell_rounded,
                title: 'Nothing here',
                message: 'List an item from its detail screen and it shows up.',
              ),
              _ => ListView(
                padding: SdContentPaddingV3.screen(context),
                children: <Widget>[
                  AppListCard(
                    children: listings
                        .map(
                          (Listing listing) => AppListRow(
                            title: listing.title,
                            subtitle: _subtitle(listing, now),
                            icon: Symbols.sell_rounded,
                            iconTint: _tint(context, listing.status),
                            trailingText: context.money(listing.price),
                            onTap: () =>
                                context.push(AppRoutes.item(listing.itemId)),
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
  static String _subtitle(Listing listing, DateTime now) {
    if (listing.lastError != null) {
      return '${listing.marketplace.displayName} · ${listing.lastError}';
    }

    final int? days = listing.daysLive(now);

    return <String>[
      listing.marketplace.displayName,
      ListingStatusLabel.of(listing.status),
      if (days != null) 'live ${days}d',
      if (listing.viewCount != null) '${listing.viewCount} views',
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

/// The words for a listing status. `domain/` holds none (hard rule 7).
final class ListingStatusLabel {
  static String of(ListingStatus status) => switch (status) {
    ListingStatus.draft => 'Draft',
    ListingStatus.active => 'Active',
    ListingStatus.paused => 'Paused',
    ListingStatus.ended => 'Ended',
    ListingStatus.sold => 'Sold',
    ListingStatus.error => 'Needs attention',
  };
}
