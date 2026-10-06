import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/item_card.dart';
import '../../../../../core/widgets/mark_sold_sheet.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/domain/enums/item_status.dart';
import '../../../../inventory/domain/services/item_transition.dart';
import '../../../../inventory/providers.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/domain/services/listings_by_item.dart';
import '../../../../listings/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../providers.dart';
import '../../widgets/cannot_sell_sheet.dart';

part 'record_sale_screen_item_list.dart';

/// The second of the two ways an order is created — the Orders side of it
/// (`lib/features/orders/CLAUDE.md`).
///
/// **It picks the item and then hands over to `MarkSoldSheet`**, the same
/// sheet Inventory's Actions opens. The flow is one flow entered from either
/// end: from an item the seller already has open, or from Orders having just
/// sold something.
///
/// **Everything is offered, and what cannot be sold is disabled** — owner's
/// rule. A row filtered out says the item does not exist, which is the wrong
/// answer for a jacket the seller marked sold last week; a greyed row with
/// "It has already left inventory" under it is the right one. A business with
/// no items at all is still sent to Inventory rather than shown a form it
/// cannot complete.
///
/// **This is also the only place a bundle is built.** Long-pressing a row
/// starts a selection — the same gesture Inventory uses — and the pinned bar
/// sells the whole selection as one order. It lives here rather than on an
/// item's action sheet because a bundle starts with the seller choosing, and
/// an item's own screen has already chosen.
class RecordSaleScreen extends ConsumerStatefulWidget {
  const RecordSaleScreen({super.key});

  @override
  ConsumerState<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends ConsumerState<RecordSaleScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // After the first frame: writing to a provider during build is what
    // Riverpod asserts on, and the query has to start empty or the screen
    // opens filtered by the last visit's search.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordSaleQueryProvider.notifier).clear();
      // A bundle half-built when the seller left last time is not one they
      // came back for.
      ref.read(recordSaleSelectionProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sell everything ticked as one order.
  Future<void> _sellBundle() async {
    final List<Item> selected = ref.read(recordSaleSelectionItemsProvider);
    final NavigatorState navigator = Navigator.of(context);

    if (selected.isEmpty) return;

    final bool? recorded = await MarkSoldSheet.show(context, selected);

    if (!mounted || !(recorded ?? false)) return;

    ref.read(recordSaleSelectionProvider.notifier).clear();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> items = ref.watch(recordSaleItemsProvider);
    final AsyncValue<List<Item>> source = ref.watch(itemsProvider);
    final List<Item> selected = ref.watch(recordSaleSelectionItemsProvider);
    // Nothing is filtered out any more, so an empty list is an empty business
    // rather than a shelf that happens to be clear.
    final bool hasAny = (source.value ?? const <Item>[]).isNotEmpty;

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.recordSaleTitle),
      // Only once something is ticked: a bundle button over an empty
      // selection is an action that would write an order of nothing.
      bottomNavigationBar: selected.isEmpty
          ? null
          : AppPinnedAction(
              label: context.l10n.recordSaleSellBundle(selected.length),
              icon: AppIconConstant.shoppingBag,
              onPressed: _sellBundle,
              secondary: SdButtonV3(
                variant: SdButtonVariantV3.text,
                label: context.l10n.commonClear,
                onPressed: () =>
                    ref.read(recordSaleSelectionProvider.notifier).clear(),
              ),
            ),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          // The field is not focused on arrival: a seller with twelve items
          // is picking from a list, and a keyboard would cover it.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdSearchFieldV3(
              controller: _controller,
              hint: context.l10n.recordSaleSearchHint,
              clearTooltip: context.l10n.commonClear,
              onChanged: (String value) =>
                  ref.read(recordSaleQueryProvider.notifier).update(value),
            ),
          ),
          SizedBox(height: SdContentPaddingV3.listItemGap),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Item>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              AsyncError<List<Item>>() => SdEmptyStateV3(
                icon: AppIconConstant.error,
                title: context.l10n.inventoryLoadFailed,
                message: context.l10n.commonCouldNotLoad,
              ),
              _ when items.isEmpty => _EmptyShelf(hasAny: hasAny),
              _ => _SaleItemList(items: items),
            },
          ),
        ],
      ),
    );
  }
}
