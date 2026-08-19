import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/date_picker_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../../core/widgets/receipt_field.dart';
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

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _vendor = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  /// The id is minted here rather than in the controller, so a receipt
  /// uploaded before the expense is saved already lands under the record it
  /// belongs to.
  final String _expenseId = const Uuid().v4();

  ExpenseCategory _category = ExpenseCategory.shipping;
  DateTime _date = DateTime.now();
  String? _receiptUrl;
  bool _isRecurring = false;

  @override
  void dispose() {
    _amount.dispose();
    _vendor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _attach({required bool fromCamera}) async {
    try {
      final String? url = await ref
          .read(expenseControllerProvider.notifier)
          .attachReceipt(recordId: _expenseId, fromCamera: fromCamera);

      // Null means the seller cancelled the picker, which is not a change.
      if (url == null || !mounted) return;

      setState(() => _receiptUrl = url);
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
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
            id: _expenseId,
            category: _category,
            amount: _amount.text,
            date: _date,
            vendor: _vendor.text,
            notes: _notes.text,
            receiptUrl: _receiptUrl,
            isRecurring: _isRecurring,
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, 'Expense recorded');
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(expenseControllerProvider);
    final DateTime now = DateTime.now();

    return SdBottomSheetV3(
      title: context.l10n.expensesNewExpense,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PickerField(
            label: context.l10n.commonCategory,
            icon: Symbols.category_rounded,
            value: ExpenseCategoryLabel.of(_category),
            onTap: () async {
              final ExpenseCategory? picked =
                  await OptionPickerSheet.show<ExpenseCategory>(
                    context,
                    title: context.l10n.commonCategory,
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
            label: context.l10n.commonAmount,
            controller: _amount,
            currency: ref.watch(workspaceCurrencyProvider),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: context.l10n.commonDate,
            icon: Symbols.calendar_month_rounded,
            value: DateTimeUtils.mediumDate(_date, locale: context.localeTag),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(now.year - DatePickerConstant.recentEntryYearsBack),
                lastDate: now,
              );

              if (picked == null) return;

              setState(() => _date = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.expensesVendorOptional,
            controller: _vendor,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.sourcingNotesOptional,
            controller: _notes,
            maxLines: 2,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          ReceiptField(
            url: _receiptUrl,
            isBusy: isBusy,
            onCamera: () => _attach(fromCamera: true),
            onLibrary: () => _attach(fromCamera: false),
            onRemove: () => setState(() => _receiptUrl = null),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isRecurring,
            onChanged: (bool value) => setState(() => _isRecurring = value),
            title: Text(
              context.l10n.expensesHappensEveryMonth,
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
    );
  }
}
