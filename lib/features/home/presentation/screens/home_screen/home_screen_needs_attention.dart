part of 'home_screen.dart';

/// The four things that can be waiting on a seller, each with its count.
///
/// A block renders **only when it has something in it**. A permanent list of
/// zeroes trains the eye to skip the whole section, which defeats the one
/// thing this screen exists to do.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> pending = ref.watch(ordersNeedingActionProvider);
    final List<Item> stale = ref.watch(staleItemsProvider);
    final List<Item> unlisted = ref.watch(unlistedItemsProvider);
    final DateTime now = DateTime.now();

    final int overdue = pending
        .where((Order order) => order.isOverdue(now) ?? false)
        .length;

    final List<Widget> rows = <Widget>[
      if (pending.isNotEmpty)
        _AttentionRow(
          icon: Symbols.local_shipping_rounded,
          label: 'Orders to ship',
          count: pending.length,
          // An overdue order is a different problem from a pending one: the
          // penalty has already started. Saying so on the row is the whole
          // value of the block.
          detail: overdue > 0 ? '$overdue overdue' : 'none overdue',
          tint: overdue > 0
              ? context.sdTheme3.danger
              : context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.orders),
        ),
      if (unlisted.isNotEmpty)
        _AttentionRow(
          icon: Symbols.sell_rounded,
          label: 'Items to list',
          count: unlisted.length,
          detail: 'in stock, not listed anywhere',
          tint: context.sdTheme3.info,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      if (stale.isNotEmpty)
        _AttentionRow(
          icon: Symbols.hourglass_bottom_rounded,
          label: 'Stale inventory',
          count: stale.length,
          detail: 'listed over 60 days',
          tint: context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.inventory),
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: rows.isEmpty
          ? const _AllClear()
          : SdCardV3(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < rows.length; i++) ...<Widget>[
                    rows[i],
                    if (i != rows.length - 1)
                      Padding(
                        padding: EdgeInsets.only(
                          // Indented to clear the icon tile, so the rule
                          // separates the text column rather than cutting the
                          // whole card in half.
                          left:
                              SdSpacingConstant.w16 +
                              SdIconTileSizeV3.medium.box +
                              SdSpacingConstant.w12,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: context.sdTheme3.divider,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
