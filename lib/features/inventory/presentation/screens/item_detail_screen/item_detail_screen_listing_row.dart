part of 'item_detail_screen.dart';

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
                context.l10n.listingViewCount(listing.viewCount!),
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
