part of 'expenses_screen.dart';

/// The monthly costs that are owed, each one tap from being recorded.
///
/// **It proposes; nothing posts on its own** — `docs/rules/DECISIONS.md` § A
/// recurring expense is proposed, never posted on its own. Storage rent
/// cancelled in March that keeps posting in April is a wrong figure nobody
/// finds until it is on a tax return.
///
/// Absent entirely when nothing is due, rather than an empty card saying so:
/// a section that is usually empty trains a seller to scroll past it.
class _DueRecurring extends ConsumerWidget {
  const _DueRecurring();

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense series,
  ) async {
    try {
      await ref.read(expenseControllerProvider.notifier).recordNext(series);

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(
        context,
        context.l10n.expensesRecurringRecorded,
      );
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
    final List<RecurringExpense> due = ref.watch(dueRecurringExpensesProvider);
    final bool isBusy = ref.watch(expenseControllerProvider);

    if (due.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.sectionGap),
        SdSectionHeaderV3(
          title: context.l10n.expensesRecurringDue,
          subtitle: context.l10n.expensesRecurringDueNote,
          first: true,
        ),
        AppListCard(
          children: due
              .map(
                (RecurringExpense series) => AppListRow(
                  title: ExpenseCategoryLabel.of(series.latest.category),
                  subtitle: <String>[
                    context.l10n.expensesRecurringDueOn(
                      DateTimeUtils.mediumDate(
                        series.due,
                        locale: context.localeTag,
                      ),
                    ),
                    if (series.latest.vendor != null) series.latest.vendor!,
                  ].join(' · '),
                  icon: AppIconConstant.autorenew,
                  showChevron: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.money(series.latest.amount),
                        style: context.textTheme3.bodyMedium!.tabular3.copyWith(
                          color: context.sdTheme3.textPrimary,
                        ),
                      ),
                      SizedBox(width: SdSpacingConstant.w8),
                      SdButtonV3(
                        variant: SdButtonVariantV3.secondary,
                        size: SdButtonSizeV3.small,
                        label: context.l10n.expensesRecurringRecord,
                        onPressed: isBusy
                            ? null
                            : () => _record(context, ref, series),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
