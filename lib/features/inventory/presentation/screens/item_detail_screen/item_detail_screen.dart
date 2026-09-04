import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_detail_action_button.dart';
import '../../../../../core/widgets/app_editable_section.dart';
import '../../../../../core/widgets/app_photo.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../../listings/providers.dart';
import '../../../../sourcing/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/enums/item_status.dart';
import '../../../domain/enums/item_warning.dart';
import '../../../domain/services/item_consistency.dart';
import '../../../domain/services/item_transition.dart';
import '../../../item_block_presenter.dart';
import '../../../providers.dart';
import '../../controllers/item_actions_controller.dart';
import '../../controllers/item_detail_edit_controller.dart';
import '../../widgets/item_actions_sheet.dart';
import '../../widgets/item_field.dart';
import '../../widgets/item_warning_lines.dart';

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
            AppDetailActionButton(
              label: context.l10n.commonActions,
              onPressed: () =>
                  ItemActionsSheet.show(context, value, isOnDetail: true),
            ),
        ],
      ),
      body: switch (item) {
        AsyncLoading<Item?>() when !item.hasValue => const SdLoadingV3Page(),
        AsyncError<Item?>() => SdEmptyStateV3(
          icon: AppIconConstant.error,
          title: context.l10n.itemLoadFailed,
          message: context.l10n.commonCouldNotLoad,
        ),
        // Null rather than an error: the row may have been deleted by a
        // teammate while this screen was open, which is not a failure.
        AsyncData<Item?>(value: null) => SdEmptyStateV3(
          icon: AppIconConstant.searchOff,
          title: context.l10n.itemNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
        _ => _ItemBody(item: item.value!),
      },
    );
  }
}
