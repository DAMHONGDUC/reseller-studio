part of 'item_detail_screen.dart';

/// The top of Item detail: what the item is and the three figures a seller
/// opens it for, before any section (`docs/UI_POLISH_PLAN.md`).
///
/// Quiet on purpose — no hero, no tint: the screen keeps its one loud
/// element for whatever needs attention.
class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final String? photo = item.photoUrls.isEmpty ? null : item.photoUrls.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Hero(
              tag: ItemCard.photoHeroTag(item.id),
              child: AppPhoto(url: photo, size: ItemCardMetricConstant.thumbnail),
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme3.titleMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                  SizedBox(height: SdSpacingConstant.h4),
                  Wrap(
                    spacing: SdSpacingConstant.w6,
                    runSpacing: SdSpacingConstant.h4,
                    children: <Widget>[
                      SdBadgeV3(
                        label: item.status.label(context),
                        color: item.status.color(context),
                        size: SdBadgeSizeV3.compact,
                      ),
                      if (item.isDropship)
                        SdBadgeV3(
                          label: item.fulfilment.label(context),
                          color: item.fulfilment.color(context),
                          size: SdBadgeSizeV3.compact,
                        ),
                      if (item.condition != null)
                        SdBadgeV3(
                          label: item.condition!.label(context),
                          color: item.condition!.color(context),
                          size: SdBadgeSizeV3.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Figure(
              label: context.l10n.itemCost,
              value: context.money(item.purchasePrice),
              align: CrossAxisAlignment.start,
            ),
            _Figure(
              label: context.l10n.itemExpectedPrice,
              value: context.money(item.expectedPrice),
              align: CrossAxisAlignment.center,
            ),
            _Figure(
              label: context.l10n.commonQuantity,
              value: '${item.quantityOnHand}',
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
      ],
    );
  }
}

/// One figure in the summary: a label over its value.
///
/// The row spreads them edge to edge, so each lines up with its own edge.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.align});

  final String label;
  final String value;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Text(label, style: context.textTheme3.bodySmall!.muted3(context)),
        SizedBox(height: SdSpacingConstant.h2),
        AnimatedSwitcher(
          duration: SdMotionV3.of(context, SdMotionV3.fast),
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: context.textTheme3.titleMedium!.tabular3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
