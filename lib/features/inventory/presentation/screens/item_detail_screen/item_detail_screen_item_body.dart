part of 'item_detail_screen.dart';

class _ItemBody extends StatelessWidget {
  const _ItemBody({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => ListView(
    padding: SdContentPaddingV3.screen(context),
    children: <Widget>[
      SizedBox(height: SdContentPaddingV3.topGap),
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
