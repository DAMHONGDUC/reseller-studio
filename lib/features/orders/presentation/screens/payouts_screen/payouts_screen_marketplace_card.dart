part of 'payouts_screen.dart';

/// One marketplace: what it owes, what it has paid, and the orders behind it.
///
/// **The awaiting figure carries its own caveat.** Where the platform has not
/// reported a fee the expected payout leans on `Marketplace.estimatedFeeRate`,
/// and a seller checking a bank statement has to know that before a mismatch
/// reads as a missing deposit rather than a fee estimate.
///
/// Only the unsettled orders are listed. The settled ones are a total, because
/// the question this screen answers is what is still outstanding — the history
/// is on each order's own detail screen.
class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({required this.row});

  final MarketplacePayout row;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SdSectionHeaderV3(
        title: row.marketplace.displayName,
        subtitle: row.awaitingIsEstimated
            ? context.l10n.payoutsEstimatedNote
            : null,
        first: true,
      ),
      Row(
        children: <Widget>[
          Expanded(
            child: SdStatTileV3(
              label: context.l10n.payoutsAwaiting,
              value: context.money(row.awaitingTotal),
              caption: context.l10n.payoutsOrdersAwaiting(row.awaiting.length),
              icon: Symbols.hourglass_top_rounded,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: SdStatTileV3(
              label: context.l10n.payoutsSettled,
              value: context.money(row.settledTotal),
              caption: '${row.settled.length}',
              icon: Symbols.account_balance_wallet_rounded,
            ),
          ),
        ],
      ),
      if (row.awaiting.isNotEmpty) ...<Widget>[
        SizedBox(height: SdSpacingConstant.h12),
        AppListCard(
          children: row.awaiting
              .map(
                (Order order) => AppListRow(
                  title: order.lines.isEmpty
                      ? order.id
                      : order.lines.first.title,
                  subtitle: context.l10n.payoutsOrderedOn(
                    DateTimeUtils.mediumDate(
                      order.orderedAt,
                      locale: context.localeTag,
                    ),
                  ),
                  icon: Symbols.receipt_long_rounded,
                  trailingText: context.money(
                    PayoutReconciliation.expected(order),
                  ),
                  showChevron: false,
                  onTap: () => SettleOrderSheet.show(context, order),
                ),
              )
              .toList(),
        ),
      ],
      SizedBox(height: SdContentPaddingV3.sectionGap),
    ],
  );
}
