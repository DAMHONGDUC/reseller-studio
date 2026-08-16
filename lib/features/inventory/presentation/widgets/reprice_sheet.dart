import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// Set a new asking price on one item, or on forty.
///
/// **The bulk case is the reason this exists** (hard rule 16, plan §7): stale
/// inventory is cleared by selecting a screenful and cutting the price, and a
/// screen that could only edit one row at a time is why sellers keep using
/// spreadsheets. One item is just the same sheet with a list of one.
class RepriceSheet extends ConsumerStatefulWidget {
  const RepriceSheet({required this.items, super.key});

  final List<Item> items;

  static Future<void> show(BuildContext context, List<Item> items) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => RepriceSheet(items: items),
      );

  @override
  ConsumerState<RepriceSheet> createState() => _RepriceSheetState();
}

class _RepriceSheetState extends ConsumerState<RepriceSheet> {
  /// Pre-filled only when every selected item already agrees on a price —
  /// otherwise the box would suggest a number that happens to belong to one
  /// row and quietly apply it to the rest.
  late final TextEditingController _price = TextEditingController(
    text: _sharedPrice?.toInputString() ?? '',
  );

  Money? get _sharedPrice {
    if (widget.items.isEmpty) return null;

    final Money? first = widget.items.first.askingPrice;

    if (first == null) return null;

    return widget.items.every((Item item) => item.askingPrice == first)
        ? first
        : null;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? price = Money.tryParse(_price.text, currency);
    final int count = widget.items.length;

    if (price == null) {
      SdSnackBarUtilsV3.error(context, context.l10n.repriceRequired);

      return;
    }

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .reprice(widget.items, price);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(
        context,
        count == 1
            ? context.l10n.repriceDone
            : context.l10n.repriceDoneBulk(count),
      );
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
    final int count = widget.items.length;

    return SdBottomSheetV3(
      title: count == 1
          ? context.l10n.repriceTitle
          : context.l10n.repriceTitleBulk(count),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoneyField(
            label: context.l10n.repriceNewPrice,
            controller: _price,
            currency: ref.watch(workspaceCurrencyProvider),
            helperText: count == 1 ? null : context.l10n.repriceBulkHelp,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.repriceSubmit,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
