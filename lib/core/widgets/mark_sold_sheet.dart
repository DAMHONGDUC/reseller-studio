import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/inventory/domain/entities/item.dart';
import '../../features/listings/domain/entities/listing.dart';
import '../../features/listings/domain/services/listing_pricing.dart';
import '../../features/listings/providers.dart';
import '../../features/marketplaces/domain/entities/marketplace.dart';
import '../../features/marketplaces/domain/services/marketplace_matching.dart';
import '../../features/marketplaces/providers.dart';
import '../../features/orders/domain/services/bundle_allocation.dart';
import '../../features/orders/providers.dart';
import '../../features/workspace/providers.dart';
import '../constants/date_picker_constant.dart';
import '../error/failure_presenter.dart';
import '../extensions/context_extensions.dart';
import '../money/money.dart';
import '../state/form_seed.dart';
import '../utils/date_time_utils.dart';
import 'money_field.dart';
import 'option_picker_sheet.dart';
import 'picker_field.dart';

/// Record that an item sold.
///
/// **This creates an order, not just a status change.** Profit is derived
/// from orders (hard rule 3), so an item flipped to `sold` with no order
/// behind it would disappear from every figure the product is judged on —
/// revenue, margin, ROI, sell-through, all of it.
///
/// **In `core/widgets/` because two features open it** — Inventory's Actions
/// sheet, and the Orders tab's record-sale screen once it has an item. Those
/// are the two ways an order is created, and they are one sheet on purpose
/// (`lib/features/orders/CLAUDE.md`).
///
/// **It offers only the marketplaces the items are actually on** — owner's
/// rule. A picker listing every platform the business sells on makes the
/// seller find the one of them this jacket was live at, and picking a wrong
/// one writes an order against a platform that never carried it. Items on no
/// marketplace still have to be sellable — cash in hand is a sale — so that
/// case falls back to the full list rather than to an empty picker.
///
/// **It takes a list, because an order may be a bundle.** One payment for
/// three things is one order; splitting it into three with invented prices
/// destroys the per-item ROI Sourcing exists to measure. The sale price is
/// what the buyer paid in total and `BundleAllocation` decides each line's
/// share — by expected price when every item has one, evenly otherwise, and
/// the shares always add back up to the total exactly.
class MarkSoldSheet extends ConsumerStatefulWidget {
  const MarkSoldSheet({required this.items, super.key});

  final List<Item> items;

  /// True when a sale was recorded, null when the seller dismissed the sheet.
  ///
  /// The record-sale screen pops itself on a true so the seller lands back on
  /// Orders with the new order under them; Inventory's Actions sheet has
  /// nothing to close and ignores it.
  static Future<bool?> show(BuildContext context, List<Item> items) =>
      showSdBottomSheetV3<bool>(
        context: context,
        builder: (BuildContext context) => MarkSoldSheet(items: items),
      );

  @override
  ConsumerState<MarkSoldSheet> createState() => _MarkSoldSheetState();
}

class _MarkSoldSheetState extends ConsumerState<MarkSoldSheet>
    with FormSeed<MarkSoldSheet> {
  /// Filled once the listings arrive, and refilled every time the seller
  /// picks another marketplace.
  ///
  /// **Empty until then, never a guess.** Seeding it in a field initialiser
  /// read `listingsForItemProvider` before it had emitted, so every sale
  /// opened on `Item.expectedPrice` and only showed what the platform was
  /// asking once the seller re-picked the platform they were already on.
  final TextEditingController _price = TextEditingController();

  final TextEditingController _buyer = TextEditingController();

  /// The platform's own order number.
  ///
  /// **Optional, and the only thing `PayoutCsvImport` can match on.** An
  /// order without one can never be reconciled from a payout file, so the box
  /// sits here rather than only on the order afterwards — this is the moment
  /// the seller has the number in front of them.
  final TextEditingController _externalOrderId = TextEditingController();

  /// What the platform paid, when the seller already knows it.
  ///
  /// **Left empty on purpose and optional.** Most sales are recorded before
  /// the platform pays, and a pre-filled guess is indistinguishable from a
  /// fact the moment it is saved (hard rule 3). Empty means the order's profit
  /// reads `—` and the order joins the Payouts queue.
  final TextEditingController _payout = TextEditingController();

  Marketplace? _marketplace;
  DateTime _soldAt = DateTime.now();

  /// Every listing of the items being sold, grouped by item id.
  ///
  /// **One read, filled in `build`.** The seed and the marketplace picker have
  /// to answer from the same data: two live reads resolve at different moments,
  /// which is exactly how the box came to hold the wrong number.
  Map<String, List<Listing>> _listings = const <String, List<Listing>>{};

  /// The platforms this sale may name — these items', or all of them when
  /// they are on none.
  Provider<List<Marketplace>> get _options => marketplacesForItemsProvider(
    <String>[for (final Item item in widget.items) item.id],
  );

  /// What the box should read for [marketplace].
  ///
  /// **That platform's own listing price, falling back to what the seller
  /// expects for the item** — owner's rule. An item live at £45 on eBay and
  /// £40 on Depop has two right answers and the picker is what chooses
  /// between them; a marketplace it is not listed on has none, and the
  /// expected price is the one number that is true either way
  /// (`lib/features/inventory/CLAUDE.md`).
  ///
  /// **A bundle seeds the sum of those answers.** It is a starting point and
  /// nothing more — a bundle is discounted by definition, so the seller
  /// almost always types over it.
  String _priceFor(Marketplace? marketplace) {
    final List<Money> parts = <Money>[
      for (final Item item in widget.items) ?_priceOf(item, marketplace),
    ];

    if (parts.isEmpty) return '';

    return parts
        .reduce((Money running, Money next) => running + next)
        .toInputString();
  }

  Money? _priceOf(Item item, Marketplace? marketplace) {
    final Map<String, Money> prices = ListingPricing.byMarketplace(
      _listings[item.id] ?? const <Listing>[],
    );
    final Money? listed = marketplace == null
        ? null
        : MarketplaceMatching.valueFor(marketplace, prices);

    return listed ?? item.expectedPrice;
  }

  /// What is in the price box right now, or null while it is empty.
  Money? _typedPrice(String currency) => Money.tryParse(_price.text, currency);

  /// Picking a platform moves the price with it — including over a number the
  /// seller had typed, which is the point: the box says what that marketplace
  /// is asking, and a figure left behind from the platform before it would be
  /// the wrong one presented as confirmed.
  void _selectMarketplace(Marketplace picked) {
    setState(() {
      _marketplace = picked;
      _price.text = _priceFor(picked);
    });
  }

  @override
  void dispose() {
    _price.dispose();
    _buyer.dispose();
    _externalOrderId.dispose();
    _payout.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? price = Money.tryParse(_price.text, currency);
    final List<Marketplace> marketplaces = ref.read(activeMarketplacesProvider);
    final Marketplace? marketplace = _marketplace ?? marketplaces.firstOrNull;

    if (price == null || marketplace == null) {
      SdSnackBarUtilsV3.error(context, context.l10n.markSoldPriceRequired);

      return;
    }

    try {
      await ref
          .read(recordSaleControllerProvider.notifier)
          .record(
            widget.items,
            salePrice: price,
            marketplaceId: marketplace.id,
            marketplaceName: marketplace.name,
            soldAt: _soldAt,
            buyerName: _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
            externalOrderId: _externalOrderId.text.trim().isEmpty
                ? null
                : _externalOrderId.text.trim(),
            payout: Money.tryParse(_payout.text, currency),
          );

      if (!mounted) return;

      navigator.pop(true);
      SdSnackBarUtilsV3.success(context, context.l10n.markSoldDone);
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
    final bool isBusy = ref.watch(recordSaleControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final DateTime now = DateTime.now();
    // Only the platforms this item is on — the whole list only when it is on
    // none (`marketplacesForItemProvider`).
    final List<Marketplace> marketplaces = ref.watch(_options);
    final Marketplace? marketplace = _marketplace ?? marketplaces.firstOrNull;
    final Map<String, AsyncValue<List<Listing>>> listings =
        <String, AsyncValue<List<Listing>>>{
          for (final Item item in widget.items)
            item.id: ref.watch(listingsForItemProvider(item.id)),
        };

    _listings = <String, List<Listing>>{
      for (final MapEntry<String, AsyncValue<List<Listing>>> entry
          in listings.entries)
        entry.key: entry.value.value ?? const <Listing>[],
    };

    // **Both halves of the answer have to be in.** The sheet opens on the
    // platform the item is live at, so seeding before the marketplaces or the
    // listings have arrived fills the box from `Item.expectedPrice` — and
    // `seedOnce` never comes back to correct it.
    final bool isReady =
        ref.watch(marketplacesProvider).hasValue &&
        listings.values.every((AsyncValue<List<Listing>> one) => one.hasValue);

    // Once only: re-seeding on a later frame would throw away what the seller
    // had typed (`docs/rules/SCREENS.md`).
    if (isReady) seedOnce(() => _price.text = _priceFor(marketplace));

    return SdBottomSheetV3(
      title: widget.items.length == 1
          ? context.l10n.markSoldTitle
          : context.l10n.markSoldBundleTitle(widget.items.length),
      closeTooltip: context.l10n.commonClose,
      // **It scrolls rather than grows** — a bundle carries a split line per
      // item, and the column overflowed at three. `Flexible` keeps a one-item
      // sale sized to its own rows instead of a fixed height of dead space.
      child: Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MoneyField(
                label: context.l10n.markSoldPrice,
                isRequired: true,
                controller: _price,
                currency: currency,
                // Redraws what depends on the price as it is typed: a
                // bundle's split, and the cut the payout box implies.
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              PickerField(
                label: context.l10n.markSoldOn,
                value: marketplace?.name,
                onTap: () async {
                  final Marketplace? picked =
                      await OptionPickerSheet.show<Marketplace>(
                        context,
                        title: context.l10n.commonMarketplace,
                        selected: marketplace,
                        options: marketplaces
                            .map(
                              (Marketplace marketplace) =>
                                  PickerOption<Marketplace>(
                                    value: marketplace,
                                    label: marketplace.name,
                                  ),
                            )
                            .toList(),
                      );

                  if (picked == null) return;

                  _selectMarketplace(picked);
                },
              ),
              SizedBox(height: SdSpacingConstant.h16),
              PickerField(
                label: context.l10n.markSoldDate,
                value: DateTimeUtils.mediumDate(
                  _soldAt,
                  locale: context.localeTag,
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _soldAt,
                    firstDate: DateTime(
                      now.year - DatePickerConstant.recentEntryYearsBack,
                    ),
                    lastDate: now,
                  );

                  if (picked == null) return;

                  setState(() => _soldAt = picked);
                },
              ),
              // How the one payment lands on each line. A bundle price is a
              // judgement, so the seller sees the judgement rather than finding
              // it later on three order lines.
              if (widget.items.length > 1) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h8),
                _BundleSplit(items: widget.items, total: _typedPrice(currency)),
              ],
              SizedBox(height: SdSpacingConstant.h16),
              MoneyField(
                label: context.l10n.markSoldPayout,
                controller: _payout,
                currency: currency,
                helperText: context.l10n.markSoldPayoutHelp,
                // The card under it says what this figure means the platform
                // kept, so it has to move as the figure is typed.
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
              ),
              // Only once there is something to say. An empty box is a sale
              // whose fee nobody knows yet, not a fee of nothing.
              if (_typedPrice(currency) != null &&
                  Money.tryParse(_payout.text, currency) != null) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h8),
                _ImpliedFee(
                  price: _typedPrice(currency)!,
                  payout: Money.tryParse(_payout.text, currency)!,
                ),
              ],
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.orderExternalId,
                controller: _externalOrderId,
                hint: context.l10n.orderExternalIdHint,
                helperText: context.l10n.orderExternalIdHelp,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.markSoldBuyer,
                controller: _buyer,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: SdSpacingConstant.h24),
              SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.markSoldSubmit,
                expand: true,
                busy: isBusy,
                onPressed: isBusy || marketplace == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How a bundle's one price lands on each item.
///
/// **Shown before the sale, not discovered after it.** The split is a
/// judgement `BundleAllocation` makes — by expected price when every item has
/// one, evenly otherwise — and a seller who disagrees with it can see that
/// they do while they can still change the total.
class _BundleSplit extends StatelessWidget {
  const _BundleSplit({required this.items, required this.total});

  final List<Item> items;

  /// Null while the price box is empty, which is a form that is not ready
  /// rather than a bundle worth nothing.
  final Money? total;

  @override
  Widget build(BuildContext context) {
    final Money? amount = total;

    if (amount == null) return const SizedBox.shrink();

    final List<Money> shares = BundleAllocation.across(amount, <Money?>[
      for (final Item item in items) item.expectedPrice,
    ]);
    final bool byExpected = items.every(
      (Item item) => item.expectedPrice != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          byExpected
              ? context.l10n.markSoldSplitByExpected
              : context.l10n.markSoldSplitEvenly,
          style: context.textTheme3.bodySmall!.faint3(context),
        ),
        SizedBox(height: SdSpacingConstant.h6),
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    items[i].title,
                    style: context.textTheme3.bodySmall!.muted3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Text(
                  context.money(shares[i]),
                  style: context.textTheme3.bodySmall!.tabular3.copyWith(
                    color: context.sdTheme3.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What the two boxes say the platform kept.
///
/// **Arithmetic the seller can check, not a rate they have to trust** — the
/// app no longer guesses a fee (hard rule 3), so the only thing worth showing
/// here is the subtraction it just did. It appears only once both figures are
/// in, because a cut of an unknown payout is not a number.
class _ImpliedFee extends StatelessWidget {
  const _ImpliedFee({required this.price, required this.payout});

  final Money price;
  final Money payout;

  @override
  Widget build(BuildContext context) => SdCardV3(
    layer: SdCardLayerV3.sunken,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          context.l10n.markSoldImpliedFee,
          style: context.textTheme3.bodyMedium!.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        Text(
          context.money(price - payout),
          style: context.textTheme3.titleSmall!.bold3.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
