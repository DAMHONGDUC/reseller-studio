import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/workspace/providers.dart';
import '../error/failure_presenter.dart';
import '../extensions/context_extensions.dart';
import '../money/money.dart';
import 'money_field.dart';

/// Ask for one price and hand it back.
///
/// **In `core/widgets/` because two features now ask the same question**:
/// Inventory reprices items, Listings reprices listings, and the sheet itself
/// knows about neither — it takes a title, an optional starting amount and a
/// callback. The entity, the repository and the words for "done" belong to
/// the caller.
///
/// **The bulk case is why it exists** (hard rule 16, plan §7): stale stock is
/// cleared by selecting a screenful and cutting the price. One row is the same
/// sheet with a list of one.
class PriceEntrySheet extends ConsumerStatefulWidget {
  const PriceEntrySheet({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.onSubmit,
    this.initialPrice,
    this.helperText,
    super.key,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;

  /// What to do with the amount. Throwing is how a failure is reported — the
  /// sheet shows the message and stays open so the seller can try again.
  final Future<void> Function(Money price) onSubmit;

  /// Pre-filled only when the caller can say every selected row already agrees
  /// on a price. A number that happens to belong to one row, applied to the
  /// rest, is the bug this nullability exists to prevent.
  final Money? initialPrice;

  final String? helperText;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String fieldLabel,
    required String submitLabel,
    required Future<void> Function(Money price) onSubmit,
    Money? initialPrice,
    String? helperText,
  }) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => PriceEntrySheet(
      title: title,
      fieldLabel: fieldLabel,
      submitLabel: submitLabel,
      onSubmit: onSubmit,
      initialPrice: initialPrice,
      helperText: helperText,
    ),
  );

  @override
  ConsumerState<PriceEntrySheet> createState() => _PriceEntrySheetState();
}

class _PriceEntrySheetState extends ConsumerState<PriceEntrySheet> {
  late final TextEditingController _price = TextEditingController(
    text: widget.initialPrice?.toInputString() ?? '',
  );

  /// Local, not a controller's flag: the sheet is shared, and reaching for one
  /// feature's busy state would tie it to that feature.
  bool _isBusy = false;

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
      SdSnackBarUtilsV3.error(context, context.l10n.repriceRequired);

      return;
    }

    setState(() => _isBusy = true);

    try {
      await widget.onSubmit(price);

      if (!mounted) return;

      navigator.pop();
    } catch (error) {
      // Already logged by whichever controller the callback reached.
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
    title: widget.title,
    closeTooltip: context.l10n.commonClose,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MoneyField(
          label: widget.fieldLabel,
          controller: _price,
          currency: ref.watch(workspaceCurrencyProvider),
          helperText: widget.helperText,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: SdSpacingConstant.h24),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: widget.submitLabel,
          expand: true,
          busy: _isBusy,
          onPressed: _isBusy ? null : _submit,
        ),
      ],
    ),
  );
}
