part of 'home_screen.dart';

/// The last few orders (plan §6).
///
/// Orders rather than a generic audit feed: the audit log is written by Cloud
/// Functions and does not exist yet, and a seller checking Home wants to know
/// what sold, not that someone edited a SKU. It becomes the real activity
/// stream when `activity/` is populated.
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
      child: SdCardV3(
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
