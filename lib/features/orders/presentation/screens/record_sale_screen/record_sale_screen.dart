import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/mark_sold_sheet.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/domain/enums/item_status.dart';
import '../../../../inventory/providers.dart';
import '../../../providers.dart';

part 'record_sale_screen_item_list.dart';

/// The second of the two ways an order is created — the Orders side of it
/// (`lib/features/orders/CLAUDE.md`).
///
/// **It picks the item and then hands over to `MarkSoldSheet`**, the same
/// sheet Inventory's Actions opens. The flow is one flow entered from either
/// end: from an item the seller already has open, or from Orders having just
/// sold something.
///
/// **Only what is on the shelf is offered.** An order names an item, so there
/// is nothing here to sell that inventory has never heard of — and a business
/// with nothing on hand is sent to Inventory rather than shown a form it
/// cannot complete.
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> items = ref.watch(recordSaleItemsProvider);
    final bool hasAny = ref.watch(sellableItemsProvider).isNotEmpty;
    final AsyncValue<List<Item>> source = ref.watch(itemsProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.recordSaleTitle),
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
