import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/barcode_scanner_page.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../inventory/providers.dart';
import '../../../../marketplaces/domain/enums/marketplace.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../orders/providers.dart';
import '../../../../pricing/domain/services/profit_calculator.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/services/sold_before_lookup.dart';

/// "Should I buy this?" — the calculation a reseller does standing in a shop
/// with the item in their hand (plan §11).
///
/// **It writes nothing and needs no connection.** Every input is typed, the
/// fee is estimated from the marketplace's published rate, and the answer is
/// on screen before the seller reaches the till. That is the whole design
/// constraint: a decision made in thirty seconds, in a stockroom, on one bar
/// of signal.
///
/// The maximum buy price is derived, not a rule of thumb — see
/// [PurchaseEvaluation.maximumBuyPrice]. **It can be negative**, and that is
/// shown rather than clamped: a negative maximum means the fees and postage
/// already exceed the sale price, so the item is not worth taking for free.
class PurchaseEvaluatorScreen extends ConsumerStatefulWidget {
  const PurchaseEvaluatorScreen({this.initialCode, super.key});

  /// A code the seller already scanned somewhere else, usually on the
  /// Inventory scanner finding nothing — which is exactly the moment this
  /// screen is for: something in their hand that the business does not own
  /// yet. Null when the screen was opened from Sourcing.
  final String? initialCode;

  @override
  ConsumerState<PurchaseEvaluatorScreen> createState() =>
      _PurchaseEvaluatorScreenState();
}

class _PurchaseEvaluatorScreenState
    extends ConsumerState<PurchaseEvaluatorScreen> {
  final TextEditingController _buy = TextEditingController();
  final TextEditingController _sale = TextEditingController();
  final TextEditingController _shipping = TextEditingController();

  Marketplace _marketplace = Marketplace.ebay;

  /// The last scan's answer, kept so the card stays on screen while the seller
  /// adjusts the numbers underneath it.
  SoldBefore? _soldBefore;

  /// Whether the sale price in the field came from [_soldBefore] rather than
  /// from the seller. It stops the helper claiming credit for a number they
  /// typed themselves.
  bool _saleFromHistory = false;

  /// Opens the camera, then answers the code out of the seller's own records.
  ///
  /// **No network, by design.** A comps lookup needs a marketplace API and a
  /// signal; this needs neither, and "you sold this for £28 in March" is a
  /// better answer than a stranger's asking price anyway.
  Future<void> _scan() async {
    final String? code = await BarcodeScannerPage.show(
      context,
      title: context.l10n.sourcingScanTitle,
      hint: context.l10n.sourcingScanHint,
    );

    if (code == null || !mounted) return;

    _applyCode(code, announceMiss: true);
  }

  /// Answer [code] out of the seller's own records and fill the sale price in.
  ///
  /// **Shared with the code this screen was opened on**, so arriving from the
  /// scanner and scanning again here cannot answer the same code differently.
  ///
  /// [announceMiss] is false on arrival: a snackbar firing as a screen opens
  /// reads as an error, and "no history" is an ordinary answer for something
  /// the seller has never bought before.
  void _applyCode(String code, {required bool announceMiss}) {
    final SoldBefore? found = SoldBeforeLookup.find(
      code: code,
      items: ref.read(itemsProvider).value ?? const <Item>[],
      orders: ref.read(ordersProvider).value ?? const <Order>[],
    );

    if (found == null) {
      setState(() => _soldBefore = null);

      if (announceMiss) {
        SdSnackBarUtilsV3.info(context, context.l10n.sourcingScanNoHistory);
      }

      return;
    }

    setState(() {
      _soldBefore = found;
      _sale.text = found.salePrice.toInputString();
      _saleFromHistory = true;
    });
  }

  @override
  void initState() {
    super.initState();

    final String? code = widget.initialCode;

    if (code == null || code.isEmpty) return;

    // After the first frame: the lookup reads providers and calls `setState`,
    // and neither is legal while the widget is still being built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyCode(code, announceMiss: false),
    );
  }

  @override
  void dispose() {
    _buy.dispose();
    _sale.dispose();
    _shipping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currency = ref.watch(workspaceCurrencyProvider);
    final Money zero = Money.zero(currency);
    final Money buy = Money.tryParse(_buy.text, currency) ?? zero;
    final Money? sale = Money.tryParse(_sale.text, currency);
    final Money shipping = Money.tryParse(_shipping.text, currency) ?? zero;

    // The business's own planning rate — the last estimate left in the app
    // (hard rule 3). Nothing has sold, so there is no payout to measure, and
    // this figure is never written to an order.
    final double feeRate = ref.read(planningFeeRateProvider);
    final Money fees = sale?.applyRate(feeRate) ?? zero;

    final PurchaseEvaluation? evaluation = sale == null
        ? null
        : PurchaseEvaluation(
            buyPrice: buy,
            expectedSalePrice: sale,
            expectedFees: fees,
            expectedShipping: shipping,
          );

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.sourcingShouldIBuyThis),
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
                _Verdict(evaluation: evaluation, marketplace: _marketplace),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _SoldBeforeCard(found: _soldBefore),
                SdCardV3(
                  child: Column(
                    children: <Widget>[
                      MoneyField(
                        label: context.l10n.sourcingBuyPrice,
                        controller: _buy,
                        currency: currency,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: SdSpacingConstant.h16),
                      MoneyField(
                        label: context.l10n.sourcingWhatYouThinkItSellsFor,
                        controller: _sale,
                        currency: currency,
                        helperText: _saleFromHistory
                            ? context.l10n.sourcingSalePriceFilled
                            : null,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) =>
                            setState(() => _saleFromHistory = false),
                      ),
                      SizedBox(height: SdSpacingConstant.h16),
                      PickerField(
                        label: context.l10n.commonMarketplace,
                        icon: AppIconConstant.storefront,
                        value: _marketplace.displayName,
                        onTap: () async {
                          final Marketplace? picked =
                              await OptionPickerSheet.show<Marketplace>(
                                context,
                                title: context.l10n.commonMarketplace,
                                selected: _marketplace,
                                options: Marketplace.values
                                    .map(
                                      (Marketplace marketplace) =>
                                          PickerOption<Marketplace>(
                                            value: marketplace,
                                            label: marketplace.displayName,
                                          ),
                                    )
                                    .toList(),
                              );

                          if (picked == null) return;

                          setState(() => _marketplace = picked);
                        },
                      ),
                      SizedBox(height: SdSpacingConstant.h16),
                      MoneyField(
                        label: context.l10n.sourcingPostageYouWillPay,
                        controller: _shipping,
                        currency: currency,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h16),
                Text(
                  'Fees are the platform\'s published rate, not a quote. The '
                  'real fee arrives with the order.',
                  style: context.textTheme3.bodySmall!.faint3(context),
                ),
              ],
            ),
          ),
          // The screen's one action, and it is what a seller reaches for
          // holding the item — a thumb's width from where the phone is held,
          // not three fields up the scroll.
          AppPinnedAction(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.sourcingScanAction,
            icon: AppIconConstant.qrCodeScanner,
            onPressed: _scan,
          ),
        ],
      ),
    );
  }
}

/// The answer, above the inputs.
///
/// Above rather than below because it is what the seller came for, and a
/// figure they have to scroll to is one they work out in their head instead.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.evaluation, required this.marketplace});

  final PurchaseEvaluation? evaluation;
  final Marketplace marketplace;

  @override
  Widget build(BuildContext context) {
    final PurchaseEvaluation? row = evaluation;

    if (row == null) {
      return SdCardV3(
        child: Text(
          context.l10n.sourcingEnterWhatItWouldSellFor,
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
      );
    }

    final bool clears = row.meetsTarget;

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SdBadgeV3(
            label: clears ? 'Worth buying' : 'Too expensive',
            tone: clears ? SdBadgeToneV3.success : SdBadgeToneV3.danger,
            icon: clears ? AppIconConstant.thumbUp : AppIconConstant.thumbDown,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          _EvaluationRow(
            label: context.l10n.itemExpectedProfit,
            value: context.money(row.expectedProfit),
            valueColor: row.expectedProfit.isNegative
                ? context.sdTheme3.loss
                : context.sdTheme3.profit,
          ),
          _EvaluationRow(
            label: context.l10n.sourcingExpectedRoi,
            value: context.percent(row.expectedRoi),
          ),
          _EvaluationRow(
            label: context.l10n.sourcingMostYouShouldPay,
            value: context.money(row.maximumBuyPrice),
            isEmphasis: true,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            context.l10n.sourcingTargetRoiNote(
              (PurchaseEvaluation.defaultTargetRoi * 100).round().toString(),
              marketplace.displayName,
            ),
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  const _EvaluationRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style:
              (isEmphasis
                      ? context.textTheme3.titleMedium!.bold3
                      : context.textTheme3.bodyMedium!.semiBold3)
                  .tabular3
                  .copyWith(color: valueColor ?? context.sdTheme3.textPrimary),
        ),
      ],
    ),
  );
}

/// What this thing fetched last time, when a scan found it.
///
/// **Absent rather than empty when nothing matched.** A card saying "no
/// history" on every visit is a row the eye learns to skip, and the snackbar
/// has already said so once.
class _SoldBeforeCard extends StatelessWidget {
  const _SoldBeforeCard({required this.found});

  final SoldBefore? found;

  @override
  Widget build(BuildContext context) {
    final SoldBefore? sale = found;

    if (sale == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h16),
      child: SdCardV3(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.sourcingSoldBefore,
              style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              context.l10n.sourcingSoldOnceFor(
                sale.title,
                context.money(sale.salePrice),
                DateTimeUtils.mediumDate(
                  sale.soldAt,
                  locale: context.localeTag,
                ),
              ),
              style: context.textTheme3.bodyMedium!.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              context.l10n.sourcingSoldTimes(
                sale.timesSold,
                DateTimeUtils.mediumDate(
                  sale.soldAt,
                  locale: context.localeTag,
                ),
              ),
              style: context.textTheme3.bodySmall!.faint3(context),
            ),
          ],
        ),
      ),
    );
  }
}
