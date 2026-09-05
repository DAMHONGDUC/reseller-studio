import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/presentation/controllers/item_actions_controller.dart';
import '../../../../inventory/providers.dart';
import '../../../../marketplaces/domain/enums/marketplace.dart';
import '../../../../marketplaces/domain/services/marketplace_fee_policy.dart';
import '../../../../marketplaces/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/listing.dart';
import '../../../domain/services/listing_pricing.dart';
import '../../../providers.dart';
import '../../controllers/cross_list_controller.dart';

part 'cross_list_screen_actions.dart';
part 'cross_list_screen_marketplaces.dart';

/// **The one way an item reaches a marketplace** — one item onto one or
/// several at once (plan §13).
///
/// ```text
/// Item → List → Select marketplaces → Review → Publish
/// ```
///
/// **It replaced a second, narrower flow** — owner's rule. A `List` sheet used
/// to put an item on exactly one marketplace, beside a `Cross-list` row for
/// the rest. To a seller who had not learned the difference they were the same
/// verb twice, and the narrower one refused to run once the item was already
/// listed — so the first thing it did after the first listing was show an
/// error and point at nothing. Picking one marketplace here does everything
/// that sheet did.
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
/// **There is no asking price field above the list** — owner's rule. Every
/// price on this screen belongs to the marketplace it sits under, so a second
/// box that priced nothing was one number too many: a seller filled it in and
/// still had to look down the rows to find out what it had done. The seed it
/// used to hold survives without it — a newly ticked row starts at the top
/// price the item is already live at.
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
  /// Hands the item's live listings to the controller: each one's price fills
  /// its own row, and the top of them becomes the seed a newly ticked
  /// marketplace starts at (§28 — the price inherits).
  ///
  /// Deferred to after the frame: this runs inside a build, and writing to a
  /// provider there is what Riverpod refuses outright. Both calls ignore a
  /// value the seller has already typed, so re-running on every emission of
  /// the stream cannot retype a field for them.
  void _seed(List<Listing> listings) {
    if (listings.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;

      ref.read(crossListControllerProvider.notifier)
        ..inheritPrice(ListingPricing.topPrice(listings))
        ..seedExisting(listings);
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

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
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
          icon: AppIconConstant.searchOff,
          title: context.l10n.itemNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
      );
    }

    final List<Listing> live =
        ref.watch(listingsForItemProvider(widget.itemId)).value ??
        const <Listing>[];

    _seed(live);

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
                _Marketplaces(itemId: item.id, currency: currency),
              ],
            ),
          ),
          _PinnedPublishAction(onPublish: () => _publish(item)),
        ],
      ),
    );
  }
}
