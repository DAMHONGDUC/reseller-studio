import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/utils/mileage_unit_label.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_row_icon_button.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../../tax/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/services/recurring_expense_schedule.dart';
import '../../../providers.dart';
import '../../controllers/expense_controller.dart';
import '../../widgets/expense_form_sheet.dart';

part 'expenses_screen_due_recurring.dart';

/// Expenses — every business cost that is not the cost of an item (plan §17).
///
/// Kept separate from `Item.purchasePrice` on purpose: an item's cost belongs
/// to a specific sale, whereas packaging tape and storage rent are overheads
/// that reduce profit without belonging to any one order. **Both feed the
/// profit statement, at different lines.**
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _add(BuildContext context) => ExpenseFormSheet.show(context);

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.expensesDeleteThisExpense,
        message: context.l10n.expensesItStopsCountingAgainstYourProfit,
        icon: AppIconConstant.warning,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () async {
              try {
                await ref
                    .read(expenseControllerProvider.notifier)
                    .delete(expense.id);

                if (!context.mounted) return;

                SdSnackBarUtilsV3.success(context, 'Deleted');
              } catch (error) {
                // Already logged by the controller.
                if (!context.mounted) return;

                SdSnackBarUtilsV3.error(
                  context,
                  FailurePresenter.message(context, error),
                );
              }
            },
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Expense>> source = ref.watch(expensesProvider);
    final List<Expense> expenses = source.value ?? const <Expense>[];
    final List<MapEntry<ExpenseCategory, Money>> totals = ref.watch(
      expenseTotalsByCategoryProvider,
    );

    final Money? total = expenses
        .map((Expense expense) => expense.amount)
        .totalOrNull();

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.commonExpenses),
      addLabel: context.l10n.homeQuickAddExpense,
      onAdd: () => _add(context),
      body: switch (source) {
        AsyncLoading<List<Expense>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when expenses.isEmpty => SdEmptyStateV3(
          icon: AppIconConstant.receipt,
          title: context.l10n.expensesNoExpensesYet,
          message: context.l10n.expensesPackagingPostageStorageMileageTheCosts,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.homeQuickAddExpense,
            onPressed: () => _add(context),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            SdStatTileV3(
              label: context.l10n.expensesTotalRecorded,
              value: context.money(total),
              caption: '${expenses.length} entries',
              icon: AppIconConstant.savings,
            ),
            const _DueRecurring(),
            if (totals.isNotEmpty) ...<Widget>[
              SizedBox(height: SdContentPaddingV3.sectionGap),
              SdSectionHeaderV3(
                title: context.l10n.analyticsByCategory,
                first: true,
              ),
              AppListCard(
                children: totals
                    .map(
                      (MapEntry<ExpenseCategory, Money> row) => AppListRow(
                        title: ExpenseCategoryLabel.of(row.key),
                        trailingText: context.money(row.value),
                        showChevron: false,
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: SdContentPaddingV3.sectionGap),
            SdSectionHeaderV3(
              title: context.l10n.expensesEverything,
              first: true,
            ),
            AppListCard(
              children: expenses
                  .map(
                    (Expense expense) => AppListRow(
                      title: ExpenseCategoryLabel.of(expense.category),
                      subtitle: <String>[
                        DateTimeUtils.mediumDate(
                          expense.date,
                          locale: context.localeTag,
                        ),
                        if (expense.vendor != null) expense.vendor!,
                        // The distance is the whole record for a mileage
                        // trip — its amount is usually zero on purpose.
                        if (expense.mileage != null)
                          '${MileageUnitLabel.distance(expense.mileage!)} '
                              '${MileageUnitLabel.of(context, ref.watch(taxJurisdictionProvider).mileageUnit).toLowerCase()}',
                        if (expense.orderId != null) 'on an order',
                        if (expense.isRecurring) 'recurring',
                      ].join(' · '),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            context.money(expense.amount),
                            style: context.textTheme3.bodyMedium!.tabular3
                                .copyWith(color: context.sdTheme3.textPrimary),
                          ),
                          SizedBox(width: SdSpacingConstant.w12),
                          AppRowIconButton(
                            icon: AppIconConstant.delete,
                            tooltip: context.l10n.actionDelete,
                            onPressed: () =>
                                _confirmDelete(context, ref, expense),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      },
    );
  }
}
