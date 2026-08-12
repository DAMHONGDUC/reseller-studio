import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// Put an item on a marketplace.
///
/// **A price and a marketplace are required here and nowhere earlier** — plan
/// §29's state-based validation. The item was allowed to exist with neither;
/// moving it to `listed` is what makes them necessary, and this sheet is where
/// they get asked for.
///
/// The price pre-fills from the item's asking price when it has one, so the
/// common case is two taps.
class ListItemSheet extends ConsumerStatefulWidget {
  const ListItemSheet({required this.item, super.key});

  final Item item;

  static Future<void> show(BuildContext context, Item item) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => ListItemSheet(item: item),
      );

  @override
  ConsumerState<ListItemSheet> createState() => _ListItemSheetState();
}

class _ListItemSheetState extends ConsumerState<ListItemSheet> {
  late final TextEditingController _price = TextEditingController(
    text: widget.item.askingPrice?.toInputString() ?? '',
  );

  Marketplace _marketplace = Marketplace.ebay;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? price = Money.tryParse(_price.text, currency);

    if (price == null) {
      SdSnackBarUtilsV3.error(context, context.l10n.listItemPriceRequired);

      return;
    }

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .listItem(
            widget.item,
            marketplace: _marketplace,
            price: price,
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.listItemDone(_marketplace.displayName),
      );
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(itemActionsControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);

    return SdBottomSheetV3(
      title: context.l10n.listItemTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PickerField(
            label: context.l10n.commonMarketplace,
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
                                caption: marketplace.hasIntegration
                                    ? context.l10n.marketplacesConnected
                                    : context.l10n.marketplaceManualCaption,
                              ),
                        )
                        .toList(),
                  );

              if (picked == null) return;

              setState(() => _marketplace = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h16),
          MoneyField(
            label: context.l10n.listItemPrice,
            controller: _price,
            currency: currency,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.listItemSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
