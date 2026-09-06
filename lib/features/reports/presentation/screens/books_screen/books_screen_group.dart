part of 'books_screen.dart';

/// How many rows of one kind are listed before the rest are counted.
///
/// A seller with two hundred estimated fees does not need two hundred rows;
/// they need to know it is two hundred and to be able to start. The header
/// carries the number, so the list can stay short enough to read.
const int _maxRowsPerGroup = 5;

/// One kind of hole, and the sales that have it.
///
/// **Renders nothing when there are none.** A permanent list of empty
/// sections trains the eye to skip the screen, which is the same reason
/// Home's Needs Attention hides its rows.
class _OrderGroup extends StatelessWidget {
  const _OrderGroup({
    required this.title,
    required this.explanation,
    required this.icon,
    required this.orders,
    this.first = false,
  });

  final String title;

  /// What is actually wrong and what entering the figure fixes. A row that
  /// only names a gap leaves the seller to guess whether it matters.
  final String explanation;

  final IconData icon;
  final List<Order> orders;
  final bool first;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();

    final List<Order> shown = orders.take(_maxRowsPerGroup).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: title,
          subtitle: explanation,
          action: Text(
            '${orders.length}',
            style: context.textTheme3.titleSmall!.tabular3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          first: first,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: AppListCard(
            children: <Widget>[
              for (final Order order in shown)
                AppListRow(
                  title: order.lines.isEmpty
                      ? context.l10n.orderFallbackTitle(order.id)
                      : order.lines.first.title,
                  subtitle: DateTimeUtils.mediumDate(
                    order.orderedAt,
                    locale: context.localeTag,
                  ),
                  icon: icon,
                  trailingText: context.money(order.salePrice),
                  onTap: () => context.push(AppRoutes.order(order.id)),
                ),
              if (orders.length > shown.length)
                AppListRow(
                  title: context.l10n.booksAndMore(
                    orders.length - shown.length,
                  ),
                  showChevron: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Buying trips with nothing filed against them.
///
/// Separate from [_OrderGroup] rather than a generic row type: a purchase is
/// not an order, it opens a different screen and it is missing a document
/// rather than a figure.
class _PurchaseGroup extends StatelessWidget {
  const _PurchaseGroup({required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) return const SizedBox.shrink();

    final List<Purchase> shown = purchases.take(_maxRowsPerGroup).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: context.l10n.booksNoReceipt,
          subtitle: context.l10n.booksNoReceiptBody,
          action: Text(
            '${purchases.length}',
            style: context.textTheme3.titleSmall!.tabular3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: AppListCard(
            children: <Widget>[
              for (final Purchase purchase in shown)
                AppListRow(
                  title: DateTimeUtils.mediumDate(
                    purchase.purchaseDate,
                    locale: context.localeTag,
                  ),
                  subtitle: context.l10n.booksPurchaseItems(purchase.itemCount),
                  icon: AppIconConstant.receiptLong,
                  trailingText: context.money(purchase.totalCost),
                  onTap: () => context.push(AppRoutes.purchase(purchase.id)),
                ),
              if (purchases.length > shown.length)
                AppListRow(
                  title: context.l10n.booksAndMore(
                    purchases.length - shown.length,
                  ),
                  showChevron: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
