import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../domain/entities/expense.dart';
import '../../../providers.dart';
import '../../controllers/expense_controller.dart';
import '../../widgets/expense_form_sheet.dart';

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
        title: 'Delete this expense?',
        message: 'It stops counting against your profit.',
        icon: Symbols.warning_rounded,
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
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
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

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: 'Expenses',
        actions: <Widget>[
          IconButton(
            icon: const SdIconV3(Symbols.add_rounded),
            tooltip: 'New expense',
            onPressed: () => _add(context),
          ),
        ],
      ),
      body: switch (source) {
        AsyncLoading<List<Expense>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when expenses.isEmpty => SdEmptyStateV3(
          icon: Symbols.receipt_rounded,
          title: 'No expenses yet',
          message:
              'Packaging, postage, storage, mileage — the costs that come off '
              'your profit but do not belong to one item.',
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Add an expense',
            onPressed: () => _add(context),
          ),
        ),
        _ => ListView(
          padding: SdContentPaddingV3.screen(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            SdStatTileV3(
              label: 'Total recorded',
              value: context.money(total),
              caption: '${expenses.length} entries',
              icon: Symbols.savings_rounded,
            ),
            if (totals.isNotEmpty) ...<Widget>[
              SizedBox(height: SdContentPaddingV3.sectionGap),
              const SdSectionHeaderV3(title: 'By category', first: true),
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
            const SdSectionHeaderV3(title: 'Everything', first: true),
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
                        if (expense.orderId != null) 'on an order',
                        if (expense.isRecurring) 'recurring',
                      ].join(' · '),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            context.money(expense.amount),
                            style: context.textTheme3.bodyMedium!.tabular3
                                .copyWith(
                                  color: context.sdTheme3.textPrimary,
                                ),
                          ),
                          IconButton(
                            icon: SdIconV3(
                              Symbols.delete_rounded,
                              size: SdIconV3.smallSize,
                              color: context.sdTheme3.textTertiary,
                            ),
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
