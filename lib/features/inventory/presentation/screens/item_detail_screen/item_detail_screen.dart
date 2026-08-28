import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_photo.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../../listings/providers.dart';
import '../../../../sourcing/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../item_label.dart';
import '../../../providers.dart';
import '../../widgets/item_actions_sheet.dart';

part 'item_detail_screen_detail_row.dart';
part 'item_detail_screen_item_body.dart';
part 'item_detail_screen_listing_row.dart';
part 'item_detail_screen_listings.dart';
part 'item_detail_screen_photos.dart';
part 'item_detail_screen_provenance.dart';

/// Item detail (plan §7).
///
/// Watches the item rather than taking it as an argument, so an edit made on
/// another device — or by a teammate — appears here without a reload, and so
/// a deep link into this screen works with only an id.
///
/// **Every action lives behind one button.** Seven verbs across the app bar
/// would each get an icon nobody recognises; one sheet names them in words,
/// and the ones that would be refused say which field is missing rather than
/// disappearing.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Item?> item = ref.watch(itemProvider(itemId));
    final Item? value = item.value;

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: value?.title ?? context.l10n.itemTitleFallback,
        subtitle: value?.sku,
        actions: <Widget>[
          if (value != null)
            Padding(
              padding: EdgeInsets.only(right: SdSpacingConstant.w8),
              child: SdButtonV3(
                variant: SdButtonVariantV3.secondary,
                size: SdButtonSizeV3.small,
                label: context.l10n.itemActions,
                icon: Symbols.tune_rounded,
                onPressed: () => ItemActionsSheet.show(context, value),
              ),
            ),
        ],
      ),
      body: switch (item) {
        AsyncLoading<Item?>() when !item.hasValue => const SdLoadingV3Page(),
        AsyncError<Item?>() => SdEmptyStateV3(
          icon: Symbols.error_rounded,
          title: context.l10n.itemLoadFailed,
          message: context.l10n.commonCouldNotLoad,
        ),
        // Null rather than an error: the row may have been deleted by a
        // teammate while this screen was open, which is not a failure.
        AsyncData<Item?>(value: null) => SdEmptyStateV3(
          icon: Symbols.search_off_rounded,
          title: context.l10n.itemNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
        _ => _ItemBody(item: item.value!),
      },
    );
  }
}
