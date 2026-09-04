import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/services/item_transition.dart';
import '../../../inventory/item_block_presenter.dart';

/// Why this item cannot be sold, and where to go and fix it.
///
/// **The row is not disabled** — owner's rule (`lib/features/orders/CLAUDE.md`).
/// A greyed card tells a seller they did something wrong and nothing else; the
/// tap is what turns the refusal into an explanation.
///
/// **A sheet rather than a snackbar**, unlike the actions sheet's refusal: a
/// snackbar over a list being scanned is gone before it has been read, and
/// this one has somewhere to send the seller.
class CannotSellSheet extends StatelessWidget {
  const CannotSellSheet._({required this.item, required this.blocks});

  final Item item;

  /// Every reason at once, not the first — the same list the actions sheet
  /// turns into a message.
  final List<ItemTransitionBlock> blocks;

  static Future<void> show(
    BuildContext context, {
    required Item item,
    required List<ItemTransitionBlock> blocks,
  }) {
    SdLogger.action(LogTagConstant.order, 'Sale blocked', <String, Object>{
      'itemId': item.id,
      'status': item.status.name,
      'quantity': item.quantity,
      'blocks': blocks.map((ItemTransitionBlock b) => b.name).join(','),
    });

    return showSdBottomSheetV3<void>(
      context: context,
      builder: (BuildContext _) =>
          CannotSellSheet._(item: item, blocks: blocks),
    );
  }

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: context.l10n.recordSaleBlockedTitle,
    closeTooltip: context.l10n.commonClose,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ItemTransitionBlock block in blocks)
          Padding(
            padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SdIconV3(
                  AppIconConstant.warning,
                  size: SdIconV3.smallSize,
                  color: context.sdTheme3.warning,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: Text(
                    ItemBlockPresenter.message(context, block),
                    style: context.textTheme3.bodyMedium!.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.recordSaleBlockedHint,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h20),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.recordSaleOpenItem,
          expand: true,
          onPressed: () {
            // Pop first: leaving the sheet up behind a pushed screen means the
            // seller comes back to one they already dealt with.
            Navigator.of(context).pop();
            context.push(AppRoutes.item(item.id));
          },
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.text,
          label: context.l10n.commonClose,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
