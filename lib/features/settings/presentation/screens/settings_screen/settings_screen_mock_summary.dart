part of 'settings_screen.dart';

/// What the seeded dataset actually contains.
///
/// Shown so that "mock data is on" is a checkable statement rather than a
/// claim — the counts come from the live store, so if a screen disagrees with
/// this card, the screen is wrong.
class _MockSummary extends ConsumerWidget {
  const _MockSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MockDataSummary summary = ref.watch(mockDataSummaryProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SdSpacingConstant.w12),
      decoration: BoxDecoration(
        color: context.sdTheme3.surfaceSunken,
        borderRadius: SdRadiusV3.inputAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            summary.workspaceName,
            style: context.textTheme3.labelMedium!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            '${summary.items} items · ${summary.orders} orders · '
            '${summary.listings} listings · ${summary.sources} sources · '
            '${summary.expenses} expenses',
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            'Held in memory only. Restarting re-seeds it, so edits made here '
            'are never permanent.',
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}
