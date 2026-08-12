import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../workspace/providers.dart';
import '../controllers/expense_controller.dart';

/// Record a cost (plan §28: category, amount and date required).
class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key});

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const ExpenseFormSheet(),
  );

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  /// How far back the date picker opens. Two years covers the current and
  /// previous tax year, which is as far back as an expense is normally filed.
  static const int pickerYearsBack = 2;

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _vendor = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.shipping;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;

  @override
  void dispose() {
    _amount.dispose();
    _vendor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    if (_amount.text.trim().isEmpty) {
      SdSnackBarUtilsV3.error(context, 'Enter what it cost');

      return;
    }

    try {
      await ref
          .read(expenseControllerProvider.notifier)
          .save(
            category: _category,
            amount: _amount.text,
            date: _date,
            vendor: _vendor.text,
            notes: _notes.text,
            isRecurring: _isRecurring,
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, 'Expense recorded');
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(expenseControllerProvider);
    final DateTime now = DateTime.now();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SdBottomSheetV3(
        title: 'New expense',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PickerField(
              label: 'Category',
              icon: Symbols.category_rounded,
              value: ExpenseCategoryLabel.of(_category),
              onTap: () async {
                final ExpenseCategory? picked =
                    await OptionPickerSheet.show<ExpenseCategory>(
                      context,
                      title: 'Category',
                      selected: _category,
                      options: ExpenseCategory.values
                          .map(
                            (ExpenseCategory category) =>
                                PickerOption<ExpenseCategory>(
                                  value: category,
                                  label: ExpenseCategoryLabel.of(category),
                                ),
                          )
                          .toList(),
                    );

                if (picked == null) return;

                setState(() => _category = picked);
              },
            ),
            SizedBox(height: SdSpacingConstant.h16),
            MoneyField(
              label: 'Amount',
              controller: _amount,
              currency: ref.watch(workspaceCurrencyProvider),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            PickerField(
              label: 'Date',
              icon: Symbols.calendar_month_rounded,
              value: DateTimeUtils.mediumDate(
                _date,
                locale: context.localeTag,
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(now.year - pickerYearsBack),
                  lastDate: now,
                );

                if (picked == null) return;

                setState(() => _date = picked);
              },
            ),
            SizedBox(height: SdSpacingConstant.h16),
            SdTextFieldV3(
              label: 'Vendor (optional)',
              controller: _vendor,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            SdTextFieldV3(
              label: 'Notes (optional)',
              controller: _notes,
              maxLines: 2,
            ),
            SizedBox(height: SdSpacingConstant.h12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isRecurring,
              onChanged: (bool value) =>
                  setState(() => _isRecurring = value),
              title: Text(
                'Happens every month',
                style: context.textTheme3.bodyMedium!.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ),
            SizedBox(height: SdSpacingConstant.h16),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.actionSave,
              expand: true,
              busy: isBusy,
              onPressed: isBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
