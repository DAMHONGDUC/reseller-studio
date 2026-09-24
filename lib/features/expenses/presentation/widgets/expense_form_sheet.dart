import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/constants/date_picker_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/mileage_unit_label.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../../core/widgets/receipt_field.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../tax/domain/enums/tax_jurisdiction.dart';
import '../../../tax/domain/services/mileage_calculator.dart';
import '../../../tax/providers.dart';
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
  final TextEditingController _distance = TextEditingController();
  final TextEditingController _vendor = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  /// The id is minted here rather than in the controller, so a receipt
  /// uploaded before the expense is saved already lands under the record it
  /// belongs to.
  final String _expenseId = SdId.unique();

  ExpenseCategory _category = ExpenseCategory.shipping;
  DateTime _date = DateTime.now();
  String? _receiptUrl;
  bool _isRecurring = false;

  /// What is in [_distance], parsed. Held rather than re-parsed in `build`
  /// because the live deduction estimate has to move as the seller types.
  double? _distanceDriven;

  String? _amountError;
  String? _distanceError;

  /// A mileage claim is rated by distance at the authority's published rate,
  /// so the money is the optional half here and the distance is the required
  /// one — the opposite of every other category.
  bool get _isMileage => _category == ExpenseCategory.mileage;

  @override
  void dispose() {
    _amount.dispose();
    _distance.dispose();
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

  /// Distance is required for a mileage trip and money is not; every other
  /// category is the other way round. Errors sit under the field that is
  /// wrong rather than in a snackbar, so the seller can see which one it is.
  bool _validate() {
    final bool amountMissing = !_isMileage && _amount.text.trim().isEmpty;
    final bool distanceMissing =
        _isMileage && (_distanceDriven == null || _distanceDriven! <= 0);

    setState(() {
      _amountError = amountMissing ? context.l10n.expensesAmountRequired : null;
      _distanceError = distanceMissing
          ? context.l10n.expensesDistanceRequired
          : null;
    });

    return !amountMissing && !distanceMissing;
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    if (!_validate()) return;

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
            mileage: _isMileage ? _distanceDriven : null,
            isRecurring: _isRecurring,
          );

      if (!mounted) return;

      navigator.pop();
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
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PickerField(
            label: context.l10n.commonCategory,
            isRequired: true,
            icon: AppIconConstant.category,
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
            isRequired: !_isMileage,
            textInputAction: TextInputAction.next,
            errorText: _amountError,
            helperText: _isMileage
                ? context.l10n.expensesAmountOptionalMileage
                : null,
          ),
          if (_isMileage) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h16),
            _MileageField(
              controller: _distance,
              date: _date,
              distance: _distanceDriven,
              errorText: _distanceError,
              onChanged: (String value) => setState(
                () => _distanceDriven = double.tryParse(value.trim()),
              ),
            ),
          ],
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: context.l10n.commonDate,
            isRequired: true,
            icon: AppIconConstant.calendarMonth,
            value: DateTimeUtils.mediumDate(_date, locale: context.localeTag),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(
                  now.year - DatePickerConstant.recentEntryYearsBack,
                ),
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

/// How far the seller drove, with what it is worth underneath.
///
/// **The estimate is the point.** A distance on its own is a number nobody can
/// check; the deduction beside it is what tells a seller whether the trip was
/// worth logging, and it is rated at the published figure for the date on the
/// form rather than today's (`MileageCalculator.rateFor`).
///
/// A rate that does not exist yet renders as a sentence saying so, never as a
/// zero — telling a seller their miles are worth nothing is worse than
/// telling them it is not known (hard rule 5).
class _MileageField extends ConsumerWidget {
  const _MileageField({
    required this.controller,
    required this.date,
    required this.distance,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final DateTime date;
  final double? distance;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaxJurisdiction jurisdiction = ref.watch(taxJurisdictionProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final double? driven = distance;
    final Money? deduction = driven == null
        ? null
        : MileageCalculator.deduction(
            distance: driven,
            rate: MileageCalculator.rateFor(jurisdiction, date),
            currency: currency,
          );

    return SdTextFieldV3(
      label: context.l10n.expensesDistanceDriven,
      controller: controller,
      hint: '0',
      // Only ever built for a mileage trip, which is the one category where
      // the distance is required and the money is not.
      isRequired: true,
      errorText: errorText,
      helperText: _helper(context, driven, deduction),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      suffix: Text(
        MileageUnitLabel.of(context, jurisdiction.mileageUnit),
        style: context.textTheme3.bodySmall!.faint3(context),
      ),
    );
  }

  static String? _helper(
    BuildContext context,
    double? driven,
    Money? deduction,
  ) {
    if (driven == null || driven <= 0) return null;
    if (deduction == null) return context.l10n.expensesMileageNoRate;

    return context.l10n.expensesMileageDeducts(context.money(deduction));
  }
}
