import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../../listings/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../providers.dart';

/// Item detail (plan §7).
///
/// Watches the item rather than taking it as an argument, so an edit made on
/// another device — or by a teammate — appears here without a reload, and so
/// a deep link into this screen works with only an id.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Item?> item = ref.watch(itemProvider(itemId));

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: item.value?.title ?? 'Item',
        subtitle: item.value?.sku,
      ),
      body: switch (item) {
        AsyncLoading<Item?>() when !item.hasValue => const SdLoadingV3Page(),
        AsyncError<Item?>() => const SdEmptyStateV3(
          icon: Symbols.error_rounded,
          title: 'Could not load this item',
          message: 'Please try again.',
        ),
        // Null rather than an error: the row may have been deleted by a
        // teammate while this screen was open, which is not a failure.
        AsyncData<Item?>(value: null) => const SdEmptyStateV3(
          icon: Symbols.search_off_rounded,
          title: 'Item not found',
          message: 'It may have been deleted.',
        ),
        _ => _ItemBody(item: item.value!),
      },
    );
  }
}

class _ItemBody extends StatelessWidget {
  const _ItemBody({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => ListView(
    padding: SdContentPaddingV3.screen(context),
    children: <Widget>[
      SdCardV3(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.title,
              style: context.textTheme3.titleMedium!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Wrap(
              spacing: SdSpacingConstant.w6,
              runSpacing: SdSpacingConstant.h4,
              children: <Widget>[
                SdBadgeV3(label: item.status.name),
                if (item.condition != null)
                  SdBadgeV3(label: item.condition!.name),
                if (item.quantity > 1) SdBadgeV3(label: '×${item.quantity}'),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: SdContentPaddingV3.sectionGap),
      Text(
        'Pricing',
        style: context.textTheme3.titleSmall!.semiBold3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      SdCardV3(
        child: Column(
          children: <Widget>[
            _DetailRow(label: 'Cost', value: context.money(item.purchasePrice)),
            _DetailRow(
              label: 'Asking price',
              value: context.money(item.askingPrice),
            ),
            _DetailRow(
              label: 'Minimum price',
              value: context.money(item.minimumPrice),
            ),
            _DetailRow(
              label: 'Expected profit',
              value: context.money(item.expectedProfit),
              // Hard rule 5: an em dash is not a figure, so it must not be
              // tinted as though it were good or bad news.
              valueColor: item.expectedProfit == null
                  ? null
                  : item.expectedProfit!.isNegative
                  ? context.sdTheme3.loss
                  : context.sdTheme3.profit,
            ),
          ],
        ),
      ),
      SizedBox(height: SdContentPaddingV3.sectionGap),
      Text(
        'Listings',
        style: context.textTheme3.titleSmall!.semiBold3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      _Listings(itemId: item.id),
      if (item.notes != null) ...<Widget>[
        SizedBox(height: SdContentPaddingV3.sectionGap),
        Text(
          'Notes',
          style: context.textTheme3.titleSmall!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdCardV3(
          child: Text(
            item.notes!,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
      ],
    ],
  );
}

/// Every marketplace this item is live on — the cross-listing view from the
/// item's side (plan §13).
class _Listings extends ConsumerWidget {
  const _Listings({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(itemId)).value ?? const <Listing>[];

    if (listings.isEmpty) {
      return SdCardV3(
        child: Text(
          'Not listed anywhere yet.',
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
      );
    }

    return SdCardV3(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < listings.length; i++) ...<Widget>[
            _ListingRow(listing: listings[i]),
            if (i != listings.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: context.sdTheme3.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: SdContentPaddingV3.row,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                listing.marketplace.displayName,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ),
            Text(
              context.money(listing.price),
              style: context.textTheme3.bodyMedium!.tabular3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h6),
        Row(
          children: <Widget>[
            SdBadgeV3(
              label: listing.status.name,
              tone: listing.status == ListingStatus.error
                  ? SdBadgeToneV3.danger
                  : listing.status.isLive
                  ? SdBadgeToneV3.success
                  : SdBadgeToneV3.neutral,
            ),
            if (listing.viewCount != null) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w8),
              Text(
                '${listing.viewCount} views',
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
            ],
          ],
        ),
        // The platform's own rejection message. Surfaced deliberately: it is
        // the seller's action item, not the kind of internal error hard rule 6
        // forbids showing.
        if (listing.lastError != null) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h6),
          Text(
            listing.lastError!,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.danger,
            ),
          ),
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme3.bodyMedium!.semiBold3.tabular3.copyWith(
            color: valueColor ?? context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
