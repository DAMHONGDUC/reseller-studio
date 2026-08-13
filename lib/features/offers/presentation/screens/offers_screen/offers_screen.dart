import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/offer.dart';
import '../../../providers.dart';
import '../../controllers/offer_actions_controller.dart';
import '../../offer_filter_label.dart';

part 'offers_screen_card.dart';
part 'offers_screen_counter_sheet.dart';

/// Offers (plan §8) — `Pending | Accepted | Declined | Expired`.
///
/// **Pending opens first**, unlike every other filtered list in the app, which
/// opens on "All". An offer is the only thing here with a countdown attached:
/// the tab a seller wants is the one with a deadline, and there is no "all
/// offers" question worth asking.
///
/// Each card shows how far below the asking price the buyer came, because
/// that is the number the decision turns on and making the seller work it out
/// is the whole reason offers get ignored.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Offer>> source = ref.watch(offersProvider);
    final List<Offer> offers = ref.watch(visibleOffersProvider);
    final Map<OfferFilter, int> counts = ref.watch(offerCountsProvider);
    final OfferFilter selected = ref.watch(offerFilterProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.offersTitle),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SizedBox(
            height: SdContentPaddingV3.filterStrip,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
                vertical: SdContentPaddingV3.filterStripGap,
              ),
              itemCount: OfferFilter.values.length,
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(width: SdSpacingConstant.w8),
              itemBuilder: (BuildContext context, int index) {
                final OfferFilter filter = OfferFilter.values[index];

                return SdFilterChipV3(
                  label: OfferFilterLabel.of(context, filter),
                  count: counts[filter],
                  selected: filter == selected,
                  onSelected: () =>
                      ref.read(offerFilterProvider.notifier).select(filter),
                );
              },
            ),
          ),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Offer>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              AsyncError<List<Offer>>() => SdEmptyStateV3(
                icon: Symbols.error_rounded,
                title: context.l10n.offersLoadFailed,
                message: context.l10n.commonCouldNotLoad,
              ),
              _ when offers.isEmpty => SdEmptyStateV3(
                icon: Symbols.local_offer_rounded,
                title: context.l10n.commonNothingHere,
                message: context.l10n.offersNoMatch,
              ),
              _ => ListView.separated(
                padding: SdContentPaddingV3.screen(context),
                itemCount: offers.length,
                separatorBuilder: (BuildContext context, int index) =>
                    SizedBox(height: SdContentPaddingV3.listItemGap),
                itemBuilder: (BuildContext context, int index) =>
                    _OfferCard(offer: offers[index]),
              ),
            },
          ),
        ],
      ),
    );
  }
}
