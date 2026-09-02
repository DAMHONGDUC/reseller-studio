part of 'tax_screen.dart';

/// Everything an accountant needs for this year, in one action.
///
/// **The feature the app already had every part of and never finished.** Sales,
/// expenses and the summary each exported on their own, spanning every year
/// the seller had ever traded, and the seller had to remember to run all three
/// and then explain which file was which. At year end, with a deadline, that
/// is the point people give up and open a spreadsheet.
///
/// **The completeness line is why this is worth handing over.** A summary is
/// only as exact as the rows under it: "128 sales checked, 0 estimated" is
/// what tells an accountant the fees are the platform's real ones rather than
/// this app's guess. Without it they have to ask, and the answer is a
/// conversation nobody wants to have in April.
class _ExportPack extends ConsumerWidget {
  const _ExportPack();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    // The Tax screen itself stays free: a seller may always read their own
    // figures. What Premium buys is handing them over in one action.
    if (!ref.read(hasFeatureProvider(PlanFeature.taxExport))) {
      await PlanBlockSheet.show(
        context,
        block: PlanBlock.featureLocked,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    try {
      await ref.read(reportControllerProvider.notifier).exportTaxPack();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookkeepingGaps gaps = ref.watch(taxYearGapsProvider);
    final bool isBusy = ref.watch(reportControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(title: context.l10n.taxPackTitle),
        SdCardV3(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.l10n.taxPackChecked(gaps.checkedOrders),
                style: context.textTheme3.bodyMedium!.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              SizedBox(height: SdSpacingConstant.h4),
              Text(
                gaps.isClear
                    ? context.l10n.taxPackExact
                    : context.l10n.taxPackApproximate(
                        gaps.estimatedFees.length,
                        gaps.unknownCost.length,
                      ),
                style: context.textTheme3.bodySmall!.copyWith(
                  // Amber, never red: an estimate is not an error, and the
                  // pack is still exportable — it just says so out loud.
                  color: gaps.isClear
                      ? context.sdTheme3.textSecondary
                      : context.sdTheme3.warning,
                ),
              ),
              if (!gaps.isClear) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h8),
                SdButtonV3(
                  variant: SdButtonVariantV3.text,
                  label: context.l10n.taxPackFixFirst,
                  size: SdButtonSizeV3.small,
                  onPressed: () => context.push(AppRoutes.books),
                ),
              ],
              SizedBox(height: SdSpacingConstant.h12),
              SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.taxPackExport,
                icon: AppIconConstant.download,
                expand: true,
                busy: isBusy,
                onPressed: isBusy ? null : () => _export(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
