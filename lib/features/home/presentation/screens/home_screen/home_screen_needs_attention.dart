part of 'home_screen.dart';

/// The things that can be waiting on a seller, each with its count.
///
/// The four the plan names (§6) — orders to ship, offers waiting, items to
/// list, stale inventory — and one the plan does not: money a marketplace
/// should have paid by now. That row is here because it is the only one that
/// hands the seller money back rather than work, and a payout that never
/// arrives is invisible until somebody goes looking for it.
///
/// A block renders **only when it has something in it**. A permanent list of
/// zeroes trains the eye to skip the whole section, which defeats the one
/// thing this screen exists to do.
///
/// **With no rows, what the section says depends on whether the business has
/// started.** "All clear" is a report on work, and a new account has none —
/// see `WorkspaceActivity`.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  /// How long the most urgent waiting offer has left.
  ///
  /// `pendingOffersProvider` already sorts by deadline, so the first is the
  /// one that costs money to ignore. Offers with no deadline sort last and are
  /// said to have none rather than being given a fake one.
  static String _closingDetail(
    BuildContext context,
    List<Offer> offers,
    DateTime now,
  ) {
    final DateTime? soonest = offers.first.expiresAt;

    if (soonest == null) return context.l10n.homeOffersNoDeadline;

    return context.l10n.homeOffersClosingIn(
      DateTimeUtils.compactRemaining(soonest.difference(now)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> pending = ref.watch(ordersNeedingActionProvider);
    final List<Offer> offers = ref.watch(pendingOffersProvider);
    final List<Item> stale = ref.watch(staleItemsProvider);
    final List<Item> unlisted = ref.watch(unlistedItemsProvider);
    final List<Order> unpaid = ref.watch(ordersAwaitingPayoutListProvider);
    final int overduePayouts = ref.watch(overduePayoutsProvider).length;
    final DateTime now = ref.watch(clockProvider).now();

    final int overdue = pending
        .where((Order order) => order.isOverdue(now) ?? false)
        .length;

    final List<Widget> rows = <Widget>[
      if (pending.isNotEmpty)
        _AttentionRow(
          icon: AppIconConstant.localShipping,
          label: context.l10n.homeOrdersToShip,
          count: pending.length,
          // An overdue order is a different problem from a pending one: the
          // penalty has already started. Saying so on the row is the whole
          // value of the block.
          detail: overdue > 0
              ? context.l10n.homeOrdersOverdue(overdue)
              : context.l10n.homeOrdersNoneOverdue,
          tint: overdue > 0
              ? context.sdTheme3.danger
              : context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.orders),
        ),
      // Second, not last: an offer has somebody else's clock on it, and it is
      // the only row here that expires whether or not the seller acts.
      if (offers.isNotEmpty)
        _AttentionRow(
          icon: AppIconConstant.localOffer,
          label: context.l10n.homeOffersWaiting,
          count: offers.length,
          detail: _closingDetail(context, offers, now),
          tint: context.sdTheme3.info,
          onTap: () => context.push(AppRoutes.offers),
        ),
      // Third: it is money already earned, so it outranks stock decisions
      // but not the two rows with somebody else's clock running on them.
      //
      // **Every sale still owed a figure, not only the late ones.** Nothing is
      // estimated any more (hard rule 3), so each of these is a profit the app
      // cannot show — the count is the work, and being overdue is what makes
      // one of them urgent rather than what makes it exist.
      if (unpaid.isNotEmpty)
        _AttentionRow(
          icon: AppIconConstant.payments,
          label: context.l10n.homePayoutsToRecord,
          count: unpaid.length,
          detail: overduePayouts > 0
              ? context.l10n.homePayoutOverdueDetail(
                  overduePayouts,
                  PayoutReconciliation.overdueAfterDays,
                )
              : context.l10n.homePayoutsToRecordDetail,
          tint: overduePayouts > 0
              ? context.sdTheme3.warning
              : context.sdTheme3.info,
          onTap: () => context.push(AppRoutes.payouts),
        ),
      if (unlisted.isNotEmpty)
        _AttentionRow(
          icon: AppIconConstant.sell,
          label: context.l10n.homeItemsToList,
          count: unlisted.length,
          detail: context.l10n.homeItemsToListDetail,
          tint: context.sdTheme3.info,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      if (stale.isNotEmpty)
        _AttentionRow(
          icon: AppIconConstant.hourglassBottom,
          label: context.l10n.homeStaleInventory,
          count: stale.length,
          // The workspace's own threshold, never a literal: a business that
          // set 14 days was being told its stock had sat for 60.
          detail: context.l10n.homeStaleDetail(
            ref.watch(staleThresholdProvider).inDays,
          ),
          tint: context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.inventory),
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: rows.isEmpty
          ? switch (ref.watch(workspaceActivityProvider)) {
              // Neither answer while the records are still arriving: a
              // returning seller must not be shown "start here" for a frame.
              WorkspaceActivity.unknown => const SizedBox.shrink(),
              WorkspaceActivity.untouched => const _StartHere(),
              WorkspaceActivity.active => const _AllClear(),
            }
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
                        child: const SdDividerV3(),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
