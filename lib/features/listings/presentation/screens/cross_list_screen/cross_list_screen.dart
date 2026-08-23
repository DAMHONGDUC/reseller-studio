import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/presentation/controllers/item_actions_controller.dart';
import '../../../../inventory/providers.dart';
import '../../../../marketplaces/domain/enums/marketplace.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/listing.dart';
import '../../../providers.dart';
import '../../controllers/cross_list_controller.dart';

part 'cross_list_screen_actions.dart';
part 'cross_list_screen_marketplaces.dart';
part 'cross_list_screen_review.dart';

/// Cross-listing (plan §13) — one item onto several marketplaces at once.
///
/// ```text
/// Item → Cross-list → Select marketplaces → Review → Publish
/// ```
///
/// **Review is not a second screen.** The plan draws it as a step, and a
/// separate page would be a tap between choosing and committing that adds
/// nothing a panel under the choices cannot say. What matters is that the
/// seller sees what each platform will take before they publish, not that
/// they see it alone.
///
/// **Required: the item and one marketplace. The price inherits** (plan §28).
/// Everything else a listing can carry — a per-platform title, a description,
/// photos — diverges later, when a seller optimises one; asking for four
/// titles here would make the fast path the slow one (hard rule 2).
///
/// **Publish writes drafts, not live listings.** Nothing is integrated yet,
/// and a row claiming to be live on eBay is a claim the app cannot back up.
class CrossListScreen extends ConsumerStatefulWidget {
  const CrossListScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<CrossListScreen> createState() => _CrossListScreenState();
}

class _CrossListScreenState extends ConsumerState<CrossListScreen> {
  final TextEditingController _price = TextEditingController();

  /// The inherited price is written into the box once, when the item first
  /// arrives. Doing it on every build would overwrite what the seller typed.
  bool _inherited = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _inheritOnce(Item item) {
    if (_inherited) return;

    _inherited = true;

    final Money? asking = item.askingPrice;

    if (asking == null) return;

    _price.text = asking.toInputString();
    // After the frame: the controller is being read by the widget that is
    // building right now, and writing to it during build is what Riverpod
    // refuses outright.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;

      ref.read(crossListControllerProvider.notifier).inheritPrice(asking);
    });
  }

  Future<void> _publish(Item item) async {
    try {
      final int count = await ref
          .read(crossListControllerProvider.notifier)
          .publish(item);

      if (count == 0 || !mounted) return;

      Navigator.of(context).pop();
      SdSnackBarUtilsV3.success(context, context.l10n.crossListDone(count));
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Item? item = ref.watch(itemProvider(widget.itemId)).value;
    final String currency = ref.watch(workspaceCurrencyProvider);

    if (item == null) {
      return SdScaffoldV3(
        appBar: SdAppBarV3(title: context.l10n.crossListTitle),
        body: SdEmptyStateV3(
          icon: Symbols.search_off_rounded,
          title: context.l10n.itemNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
      );
    }

    _inheritOnce(item);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.crossListTitle,
        subtitle: item.title,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              // No bottom inset: the pinned action owns the bottom edge.
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                MoneyField(
                  label: context.l10n.crossListPrice,
                  controller: _price,
                  currency: currency,
                  helperText: context.l10n.crossListPriceHelper,
                  onChanged: (String value) => ref
                      .read(crossListControllerProvider.notifier)
                      .setPrice(Money.tryParse(value, currency)),
                ),
                SizedBox(height: SdSpacingConstant.h24),
                _Marketplaces(itemId: item.id),
                SizedBox(height: SdSpacingConstant.h24),
                const _Review(),
              ],
            ),
          ),
          _PinnedPublishAction(onPublish: () => _publish(item)),
        ],
      ),
    );
  }
}
