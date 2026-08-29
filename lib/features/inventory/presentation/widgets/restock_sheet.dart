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
/// number on the receipt in the seller's hand. **The sheet then does the
/// arithmetic out loud** (owner's rule): what is on the shelf now, and what
/// will be there after, updating as the seller types. A box that only takes
/// an addend leaves them adding in their head to check they typed the right
/// thing.
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

  /// What the box currently says, or null when it is not a count yet — which
  /// is what the total renders as a dash rather than as the current figure.
  int? get _added {
    final int? typed = int.tryParse(_count.text.trim());

    return typed != null && typed > 0 ? typed : null;
  }

  @override
  void initState() {
    super.initState();
    // The total under the box has to move with the box, and the field is the
    // only thing that knows it changed.
    _count.addListener(_onCountChanged);
  }

  void _onCountChanged() => setState(() {});

  @override
  void dispose() {
    _count.removeListener(_onCountChanged);
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: SdSpacingConstant.h16),
        _RestockSummary(onShelf: widget.item.quantityOnHand, added: _added),
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

/// The arithmetic, spelled out: what is there, what arrived, what that makes.
///
/// A sunken card rather than helper text — it is a small statement about
/// numbers, and the total is the line the seller checks before tapping.
class _RestockSummary extends StatelessWidget {
  const _RestockSummary({required this.onShelf, this.added});

  final int onShelf;

  /// Null while the box holds nothing usable, which is what makes the total a
  /// dash instead of a figure that would look like the answer (hard rule 5).
  final int? added;

  @override
  Widget build(BuildContext context) {
    final int? total = added == null ? null : onShelf + added!;

    return SdCardV3(
      layer: SdCardLayerV3.sunken,
      child: Column(
        children: <Widget>[
          _SummaryRow(label: context.l10n.restockOnShelfNow, value: '$onShelf'),
          SizedBox(height: SdSpacingConstant.h8),
          _SummaryRow(
            label: context.l10n.restockNewTotal,
            value: total == null ? '—' : '$total',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;

  /// The line the seller is actually checking, so it carries the weight.
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(
        label,
        style: isTotal
            ? context.textTheme3.bodyMedium!.copyWith(
                color: context.sdTheme3.textSecondary,
              )
            : context.textTheme3.bodySmall!.faint3(context),
      ),
      Text(
        value,
        style: isTotal
            ? context.textTheme3.titleSmall!.bold3.tabular3.copyWith(
                color: context.sdTheme3.textPrimary,
              )
            : context.textTheme3.bodyMedium!.semiBold3.tabular3.copyWith(
                color: context.sdTheme3.textSecondary,
              ),
      ),
    ],
  );
}
