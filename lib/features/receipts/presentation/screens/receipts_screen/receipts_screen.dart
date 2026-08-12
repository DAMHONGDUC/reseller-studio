import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_photo.dart';
import '../../../providers.dart';

part 'receipts_screen_preview.dart';

/// Receipts (plan §18) — every piece of paperwork, in one place.
///
/// **There is no separate receipts collection.** A receipt is a file attached
/// to a purchase or an expense, and both already carry one; a second source of
/// truth would be two places that can disagree about whether a purchase has
/// its paperwork. See `receipts/providers.dart`.
///
/// The count that matters is at the top and it is the **missing** one. "You
/// have 14 receipts" is trivia; "9 records have none" is the thing a seller
/// wants to know the week before a tax deadline.
class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  /// How large a thumbnail is in the grid. Big enough to recognise a shop's
  /// paper by its shape, which is how anyone actually finds one.
  static double get tileSize => SdSpacingConstant.r64 * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ReceiptEntry> receipts = ref.watch(receiptsProvider);
    final int missing = ref.watch(missingReceiptCountProvider);

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Receipts'),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: 'Attached',
                  value: '${receipts.length}',
                  icon: Symbols.description_rounded,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: 'Missing',
                  value: '$missing',
                  caption: 'Purchases and expenses with no document',
                  tone: missing > 0 ? SdStatToneV3.loss : SdStatToneV3.neutral,
                  icon: Symbols.warning_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          if (receipts.isEmpty)
            const SdEmptyStateV3(
              icon: Symbols.description_rounded,
              title: 'No receipts yet',
              message:
                  'Photograph a receipt when you record a purchase or an '
                  'expense and it shows up here.',
            )
          else
            for (final ReceiptEntry receipt in receipts) ...<Widget>[
              _ReceiptRow(receipt: receipt),
              SizedBox(height: SdContentPaddingV3.listItemGap),
            ],
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt});

  final ReceiptEntry receipt;

  @override
  Widget build(BuildContext context) => SdCardV3(
    onTap: () => _ReceiptPreview.show(context, receipt),
    child: Row(
      children: <Widget>[
        AppPhoto(url: receipt.url, size: SdSpacingConstant.r64),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                receipt.title,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SdSpacingConstant.h2),
              Text(
                '${receipt.kind == ReceiptKind.purchase ? 'Purchase' : 'Expense'}'
                ' · '
                '${DateTimeUtils.mediumDate(receipt.date, locale: context.localeTag)}',
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
            ],
          ),
        ),
        Text(
          context.money(receipt.amount),
          style: context.textTheme3.bodyMedium!.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
