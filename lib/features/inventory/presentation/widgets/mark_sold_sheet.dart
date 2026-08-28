import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/date_picker_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// Record that an item sold.
///
/// **This creates an order, not just a status change.** Profit is derived
/// from orders (hard rule 3), so an item flipped to `sold` with no order
/// behind it would disappear from every figure the product is judged on —
/// revenue, margin, ROI, sell-through, all of it.
class MarkSoldSheet extends ConsumerStatefulWidget {
  const MarkSoldSheet({required this.item, super.key});

  final Item item;

  static Future<void> show(BuildContext context, Item item) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => MarkSoldSheet(item: item),
      );

  @override
  ConsumerState<MarkSoldSheet> createState() => _MarkSoldSheetState();
}

class _MarkSoldSheetState extends ConsumerState<MarkSoldSheet> {
  late final TextEditingController _price = TextEditingController(
    text: widget.item.askingPrice?.toInputString() ?? '',
  );

  final TextEditingController _buyer = TextEditingController();

  Marketplace _marketplace = Marketplace.ebay;
  DateTime _soldAt = DateTime.now();

  @override
  void dispose() {
    _price.dispose();
    _buyer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? price = Money.tryParse(_price.text, currency);

    if (price == null) {
      SdSnackBarUtilsV3.error(context, context.l10n.markSoldPriceRequired);

      return;
    }

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .markSold(
            widget.item,
            salePrice: price,
            marketplace: _marketplace,
            soldAt: _soldAt,
            buyerName: _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.markSoldDone);
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
    final bool isBusy = ref.watch(itemActionsControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final DateTime now = DateTime.now();

    return SdBottomSheetV3(
      title: context.l10n.markSoldTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoneyField(
            label: context.l10n.markSoldPrice,
            isRequired: true,
            controller: _price,
            currency: currency,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: context.l10n.markSoldOn,
            value: _marketplace.displayName,
            onTap: () async {
              final Marketplace? picked =
                  await OptionPickerSheet.show<Marketplace>(
                    context,
                    title: context.l10n.commonMarketplace,
                    selected: _marketplace,
                    options: Marketplace.values
                        .map(
                          (Marketplace marketplace) =>
                              PickerOption<Marketplace>(
                                value: marketplace,
                                label: marketplace.displayName,
                              ),
                        )
                        .toList(),
                  );

              if (picked == null) return;

              setState(() => _marketplace = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: context.l10n.markSoldDate,
            value: DateTimeUtils.mediumDate(_soldAt, locale: context.localeTag),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _soldAt,
                firstDate: DateTime(
                  now.year - DatePickerConstant.recentEntryYearsBack,
                ),
                lastDate: now,
              );

              if (picked == null) return;

              setState(() => _soldAt = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.markSoldBuyer,
            controller: _buyer,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.markSoldSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
