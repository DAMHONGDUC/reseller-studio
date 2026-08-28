import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/enums/marketplace.dart';
import '../../../domain/services/marketplace_fee_policy.dart';
import '../../controllers/marketplace_fee_controller.dart';
import '../../widgets/fee_entry_sheet.dart';

/// Marketplaces — connection status, and nothing else (plan §14).
///
/// **No token ever reaches this screen, or this app.** OAuth and every call
/// that uses a token happen in a Cloud Function; `marketplaces/{id}` in
/// Firestore holds connection *status* only and is `allow write: if false`
/// (hard rule 10). The app asks the backend; the backend asks eBay.
///
/// Nothing is connected today because no function is deployed, and the screen
/// says so plainly rather than showing a Connect button that fails. The fee
/// rate shown is the platform's published estimate, used by the buy
/// calculator — never by an order, which carries the fee the platform
/// actually charged.
class MarketplacesScreen extends ConsumerWidget {
  const MarketplacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdScaffoldV3(
    appBar: SdAppBarV3(title: context.l10n.marketplacesTitle),
    body: ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        SdCardV3(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.marketplacesSyncOffTitle,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              SizedBox(height: SdSpacingConstant.h6),
              Text(
                context.l10n.marketplacesSyncOffBody,
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        SdSectionHeaderV3(
          title: context.l10n.marketplacesFeesTitle,
          subtitle: context.l10n.marketplacesFeesBody,
          first: true,
        ),
        AppListCard(
          children: Marketplace.values
              .where(
                // "Other" is where a car-boot sale goes. It is not a platform
                // and there is nothing to connect it to — nor a fee to name.
                (Marketplace marketplace) => marketplace != Marketplace.other,
              )
              .map((Marketplace marketplace) => _FeeRow(marketplace: marketplace))
              .toList(),
        ),
      ],
    ),
  );
}


/// One platform: what it charges this business, and the way to correct it.
///
/// **The published rate is a starting point** — owner's rule. A seller on a
/// shop tier, in another country, or with a category discount pays something
/// else, and every after-fees figure in the app was quietly wrong for them.
/// The row says whose number it is, so a corrected rate cannot be mistaken for
/// the platform's own.
/// One platform: what it charges this business, and whose number that is.
///
/// **The toggle says what it toggles, on its own line** — owner's rule. A bare
/// switch in a row's trailing slot reads as "turn this marketplace off", which
/// is not a thing this screen does; the words are what stop that reading, and
/// they do not fit beside a title, a rate and a chevron.
class _FeeRow extends ConsumerWidget {
  const _FeeRow({required this.marketplace});

  final Marketplace marketplace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, double> rates = ref.watch(marketplaceFeeRatesProvider);
    final bool isOwn = MarketplaceFeePolicy.isOverridden(
      marketplace,
      overrides: rates,
    );
    final double rate = MarketplaceFeePolicy.rateFor(
      marketplace,
      overrides: rates,
    );
    final bool isBusy = ref.watch(marketplaceFeeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppListRow(
          title: marketplace.displayName,
          subtitle: context.l10n.marketplacesEstimatedFeeLine(
            (rate * 100).toStringAsFixed(1),
            isOwn
                ? context.l10n.marketplacesTapToEditFee
                : context.l10n.marketplacesEstimatedFee,
          ),
          icon: Symbols.hub_rounded,
          // Only editable while the toggle is off. On, the row is following
          // the platform, and a sheet that let the seller type a number the
          // row would then ignore is a control that lies.
          showChevron: isOwn,
          onTap: isOwn && !isBusy
              ? () => FeeEntrySheet.show(
                  context,
                  marketplace: marketplace,
                  rate: rate,
                )
              : null,
        ),
        _PublishedRateToggle(marketplace: marketplace, isOwn: isOwn),
      ],
    );
  }
}

/// **"Use published rate", named in full and per platform** — owner's rule.
///
/// On, the row follows `Marketplace.estimatedFeeRate` and cannot be edited.
/// Off, the seller owns the number.
///
/// **Turning it off seeds the correction at the published rate** rather than
/// leaving it unset. "I want my own rate" and "my rate is 13.25%" then say the
/// same thing, so nothing has to render a row that is neither following the
/// platform nor carrying a number.
class _PublishedRateToggle extends ConsumerWidget {
  const _PublishedRateToggle({required this.marketplace, required this.isOwn});

  final Marketplace marketplace;
  final bool isOwn;

  Future<void> _set(BuildContext context, WidgetRef ref, bool usePublished) =>
      ref
          .read(marketplaceFeeControllerProvider.notifier)
          .setRate(
            marketplace,
            usePublished ? null : marketplace.estimatedFeeRate,
          )
          .onError((Object error, StackTrace _) {
            // Already logged by the controller.
            if (!context.mounted) return;

            SdSnackBarUtilsV3.error(
              context,
              FailurePresenter.message(context, error),
            );
          });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBusy = ref.watch(marketplaceFeeControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: SdContentPaddingV3.row.left,
        right: SdContentPaddingV3.row.right,
        bottom: SdContentPaddingV3.row.bottom,
      ),
      // **Stacked, not side by side** — owner's rule. The label sits over the
      // control it names, so at six platforms the eye reads a column of
      // switches with a heading each rather than six sentences ending in a
      // control.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.marketplacesUsePublishedShort,
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
          Switch(
            value: !isOwn,
            onChanged: isBusy
                ? null
                : (bool usePublished) => _set(context, ref, usePublished),
          ),
        ],
      ),
    );
  }
}
