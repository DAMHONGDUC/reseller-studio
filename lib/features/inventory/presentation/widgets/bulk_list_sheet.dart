import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/services/bulk_listing_plan.dart';
import '../../../listings/providers.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// Put a whole selection up on several platforms at once.
///
/// **Listing is a batch, and it was the last verb that was not.** A reseller
/// photographs and lists twenty or thirty things in one evening; Inventory
/// already had a selection bar for reprice, move and archive, and cross-list
/// was reachable only from a single item's action sheet. Hard rule 16 calls
/// that the reason people keep using spreadsheets.
///
/// **It says what it will skip before it does anything.** Some ticked rows are
/// already on eBay, some are archived, and some have no expected price to list
/// at — a bulk action that silently did nothing to nine of forty would be
/// worse than none. `BulkListingPlan` separates the three and the summary line
/// reads them out.
///
/// **The price is each item's own** (`Item.expectedPrice`), never one number
/// typed here: forty items do not share a price, and the uplift is the one
/// thing that sensibly applies to all of them at once — a platform taking a
/// bigger cut is a reason to ask more everywhere.
class BulkListSheet extends ConsumerStatefulWidget {
  const BulkListSheet({required this.items, super.key});

  final List<Item> items;

  static Future<bool?> show(BuildContext context, List<Item> items) =>
      showSdBottomSheetV3<bool>(
        context: context,
        builder: (BuildContext context) => BulkListSheet(items: items),
      );

  @override
  ConsumerState<BulkListSheet> createState() => _BulkListSheetState();
}

class _BulkListSheetState extends ConsumerState<BulkListSheet> {
  /// The uplifts offered, as fractions of the expected price.
  ///
  /// A closed list rather than a box: this is a decision made in a second at
  /// the end of a listing session, and typing a percentage is a form.
  static const List<double> _uplifts = <double>[0, 0.05, 0.1, 0.15];

  final Set<Marketplace> _selected = <Marketplace>{};

  double _uplift = 0;

  BulkListingPlan _plan() => BulkListingPlan.from(
    items: widget.items,
    marketplaces: _selected,
    listings: ref.read(listingsProvider).value ?? const <Listing>[],
    uplift: _uplift,
  );

  Future<void> _publish() async {
    final NavigatorState navigator = Navigator.of(context);
    final BulkListingPlan plan = _plan();

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .crossListAll(plan);

      if (!mounted) return;

      navigator.pop(true);
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.bulkListDone(plan.listingCount, plan.itemCount),
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
    final BulkListingPlan plan = _plan();

    return SdBottomSheetV3(
      title: context.l10n.bulkListTitle(widget.items.length),
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n.bulkListMarketplaces,
            style: context.textTheme3.labelLarge!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Wrap(
            spacing: SdSpacingConstant.w8,
            runSpacing: SdSpacingConstant.h8,
            children: <Widget>[
              for (final Marketplace marketplace in Marketplace.values)
                SdFilterChipV3(
                  label: marketplace.displayName,
                  selected: _selected.contains(marketplace),
                  onSelected: () => setState(
                    () => _selected.contains(marketplace)
                        ? _selected.remove(marketplace)
                        : _selected.add(marketplace),
                  ),
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.bulkListPrice,
            style: context.textTheme3.labelLarge!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Wrap(
            spacing: SdSpacingConstant.w8,
            children: <Widget>[
              for (final double uplift in _uplifts)
                SdFilterChipV3(
                  label: uplift == 0
                      ? context.l10n.bulkListAtExpected
                      : context.l10n.bulkListUplift(
                          context.percent(uplift),
                        ),
                  selected: _uplift == uplift,
                  onSelected: () => setState(() => _uplift = uplift),
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          // What will happen, before it happens. The skipped count is the
          // half a seller cannot see from the ticked rows.
          Text(
            _selected.isEmpty
                ? context.l10n.bulkListPickOne
                : context.l10n.bulkListSummary(
                    plan.listingCount,
                    plan.itemCount,
                    plan.skippedCount,
                  ),
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.bulkListPublish,
            expand: true,
            busy: isBusy,
            onPressed: isBusy || plan.isEmpty ? null : _publish,
          ),
        ],
      ),
    );
  }
}
