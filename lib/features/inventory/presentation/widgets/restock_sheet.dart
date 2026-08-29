import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// How many more arrived.
///
/// **Restocking adds to the count and puts the row back in stock** — owner's
/// rule. A seller who buys five more of something that sold out is not
/// creating a new item: it is the same record, with the same cost history and
/// the same listings, and having to un-sell it by hand first was the step
/// that made people create a duplicate instead.
///
/// **The box asks how many arrived, not what the new total is** — that is the
/// number on the receipt in the seller's hand, and it is the only one they do
/// not have to work out.
class RestockSheet extends ConsumerStatefulWidget {
  const RestockSheet({required this.item, super.key});

  final Item item;

  /// What the field starts at: one is the answer for almost every restock,
  /// and a seller adding one more should not have to type anything.
  static const String defaultCount = '1';

  static Future<void> show(BuildContext context, Item item) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => RestockSheet(item: item),
      );

  @override
  ConsumerState<RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends ConsumerState<RestockSheet> {
  final TextEditingController _count = TextEditingController(
    text: RestockSheet.defaultCount,
  );

  bool _isBusy = false;

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final int? count = int.tryParse(_count.text.trim());

    if (count == null || count <= 0) {
      SdSnackBarUtilsV3.error(context, context.l10n.restockCountRequired);

      return;
    }

    setState(() => _isBusy = true);

    try {
      await ref.read(itemActionsControllerProvider.notifier).restock(<Item>[
        widget.item,
      ], count);

      if (!mounted) return;

      navigator.pop();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      setState(() => _isBusy = false);
      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: context.l10n.itemActionRestock,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdTextFieldV3(
          label: context.l10n.restockHowMany,
          controller: _count,
          keyboardType: TextInputType.number,
          helperText: context.l10n.restockHelp(widget.item.quantityOnHand),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: SdSpacingConstant.h24),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.itemActionRestock,
          expand: true,
          busy: _isBusy,
          onPressed: _isBusy ? null : _submit,
        ),
      ],
    ),
  );
}
