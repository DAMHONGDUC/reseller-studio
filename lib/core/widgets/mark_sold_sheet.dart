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

class _MarkSoldSheetState extends ConsumerState<MarkSoldSheet> {
  /// Seeded from the marketplace the sheet opens on, and refilled every time
  /// the seller picks another one.
  late final TextEditingController _price = TextEditingController(
    text: _priceFor(ref.read(_options).firstOrNull),
  );

  final TextEditingController _buyer = TextEditingController();

  /// Left empty on purpose. An empty box means "not known", and the profit
  /// statement then shows a labelled estimate — a pre-filled guess would be
  /// stored as though the platform had reported it.
  final TextEditingController _fees = TextEditingController();

  Marketplace? _marketplace;
  DateTime _soldAt = DateTime.now();

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
      for (final Item item in widget.items)
        ?_priceOf(item, marketplace),
    ];

    if (parts.isEmpty) return '';

    return parts
        .reduce((Money running, Money next) => running + next)
        .toInputString();
  }

  Money? _priceOf(Item item, Marketplace? marketplace) {
    final Map<String, Money> prices = ListingPricing.byMarketplace(
      ref.read(listingsForItemProvider(item.id)).value ?? const <Listing>[],
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
    _fees.dispose();
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
            fees: Money.tryParse(_fees.text, currency),
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

    return SdBottomSheetV3(
      title: widget.items.length == 1
          ? context.l10n.markSoldTitle
          : context.l10n.markSoldBundleTitle(widget.items.length),
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoneyField(
            label: context.l10n.markSoldPrice,
            isRequired: true,
            controller: _price,
            currency: currency,
            // Only a bundle needs this: it is what redraws the split under
            // the box as the seller types, and a single sale has no split.
            onChanged: widget.items.length == 1
                ? null
                : (_) => setState(() {}),
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
            value: DateTimeUtils.mediumDate(_soldAt, locale: context.localeTag),
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
            label: context.l10n.markSoldFees,
            controller: _fees,
            currency: currency,
            // Quotes the rate the estimate would use rather than filling the
            // box with it — typed is a fact, empty is a labelled estimate.
            helperText: marketplace == null
                ? null
                : context.l10n.orderFeeHelper(
                    marketplace.name,
                    context.percent(marketplace.feeRate, decimals: 1),
                  ),
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
