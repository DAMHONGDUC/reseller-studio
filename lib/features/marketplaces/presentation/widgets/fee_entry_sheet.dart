import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/enums/marketplace.dart';
import '../../domain/services/marketplace_fee_policy.dart';
import '../controllers/marketplace_fee_controller.dart';

/// Correct what one platform charges this business.
///
/// **A percentage, not money** — a fee is a fraction of whatever the item
/// sells for, so `PriceEntrySheet` is the wrong shape: it would ask for an
/// amount in the workspace currency and mean nothing on the next sale.
///
/// **Going back to the published rate is the row's toggle, not a button
/// here** — owner's rule. Two controls for one decision is how they end up
/// disagreeing, and this sheet only opens while the toggle already says the
/// seller owns the number.
class FeeEntrySheet extends ConsumerStatefulWidget {
  const FeeEntrySheet({required this.marketplace, required this.rate, super.key});

  final Marketplace marketplace;

  /// What the rate is right now, published or corrected.
  final double rate;

  static Future<void> show(
    BuildContext context, {
    required Marketplace marketplace,
    required double rate,
  }) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) =>
        FeeEntrySheet(marketplace: marketplace, rate: rate),
  );

  @override
  ConsumerState<FeeEntrySheet> createState() => _FeeEntrySheetState();
}

class _FeeEntrySheetState extends ConsumerState<FeeEntrySheet> {
  late final TextEditingController _percent = TextEditingController(
    text: (widget.rate * 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? percent = double.tryParse(_percent.text.trim());
    final double? rate = percent == null ? null : percent / 100;

    if (rate == null || !MarketplaceFeePolicy.isValid(rate)) {
      SdSnackBarUtilsV3.error(context, context.l10n.marketplacesFeeInvalid);

      return;
    }

    await _write(rate);
  }

  Future<void> _write(double? rate) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref
          .read(marketplaceFeeControllerProvider.notifier)
          .setRate(widget.marketplace, rate);

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
    final bool isBusy = ref.watch(marketplaceFeeControllerProvider);

    return SdBottomSheetV3(
      title: context.l10n.marketplacesEditFee(widget.marketplace.displayName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdTextFieldV3(
            label: context.l10n.marketplacesFeeLabel,
            controller: _percent,
            isRequired: true,
            // The design system's slot for a unit, so the seller can see they
            // are typing a percentage rather than an amount.
            suffix: Text(
              '%',
              style: context.textTheme3.bodyMedium!.muted3(context),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helperText: context.l10n.marketplacesFeeHelper,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.actionSave,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _save,
          ),
        ],
      ),
    );
  }
}
