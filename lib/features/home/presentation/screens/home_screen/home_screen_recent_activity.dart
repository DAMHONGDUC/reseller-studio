part of 'home_screen.dart';

/// The last few orders (plan §6).
///
/// Orders rather than a generic audit feed: the audit log is written by Cloud
/// Functions and does not exist yet, and a seller checking Home wants to know
/// what sold, not that someone edited a SKU. It becomes the real activity
/// stream when `activity/` is populated.
///
/// **It owns its section header.** Home rendered the heading and this widget
/// decided whether to render anything under it, which on a new account left
/// "Recent activity" captioning a gap. One widget answers "does this section
/// exist" or the two answers drift.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders =
        ref.watch(ordersProvider).value ?? const <Order>[];
    final List<Order> recent = orders
        .take(HomeConstant.recentActivityMaxRows)
        .toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: AppSection(
        title: context.l10n.homeRecentActivity,
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < recent.length; i++) ...<Widget>[
              _ActivityRow(order: recent[i]),
              if (i != recent.length - 1)
                Padding(
                  padding: EdgeInsets.only(
                    left:
                        SdSpacingConstant.w16 +
                        SdIconTileSizeV3.small.box +
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
