part of 'item_detail_screen.dart';

class _ItemBody extends StatelessWidget {
  const _ItemBody({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => ListView(
    padding: SdContentPaddingV3.screen(context),
    children: <Widget>[
      SizedBox(height: SdContentPaddingV3.topGap),
      if (item.photoUrls.isNotEmpty) ...<Widget>[
        _Photos(urls: item.photoUrls),
        SizedBox(height: SdContentPaddingV3.sectionGap),
      ],
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
                SdBadgeV3(label: ItemStatusLabel.of(context, item.status)),
                if (item.condition != null)
                  SdBadgeV3(
                    label: ItemConditionLabel.of(context, item.condition!),
                  ),
                if (item.quantity > 1) SdBadgeV3(label: '×${item.quantity}'),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: SdContentPaddingV3.sectionGap),
      _SectionTitle(title: context.l10n.itemPricing),
      SdCardV3(
        child: Column(
          children: <Widget>[
            _DetailRow(
              label: context.l10n.itemCost,
              value: context.money(item.purchasePrice),
            ),
            _DetailRow(
              label: context.l10n.itemAskingPrice,
              value: context.money(item.askingPrice),
            ),
            _DetailRow(
              label: context.l10n.itemMinimumPrice,
              value: context.money(item.minimumPrice),
            ),
            _DetailRow(
              label: context.l10n.itemExpectedProfit,
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
      _SectionTitle(title: context.l10n.itemProvenance),
      _Provenance(item: item),
      SizedBox(height: SdContentPaddingV3.sectionGap),
      _SectionTitle(title: context.l10n.itemListings),
      _Listings(itemId: item.id),
      if (item.description != null) ...<Widget>[
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _SectionTitle(title: context.l10n.commonDescription),
        SdCardV3(
          child: Text(
            item.description!,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
      ],
      if (item.notes != null) ...<Widget>[
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _SectionTitle(title: context.l10n.commonNotes),
        SdCardV3(
          child: Text(
            item.notes!,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
      ],
      SizedBox(height: SdContentPaddingV3.bottomGap),
    ],
  );
}

/// The heading above each block, with its gap already in it.
///
/// Extracted the moment the body had six of them: six copies of a `Text` plus
/// a `SizedBox` is six chances for one of the gaps to drift.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
    child: Text(
      title,
      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
        color: context.sdTheme3.textPrimary,
      ),
    ),
  );
}
