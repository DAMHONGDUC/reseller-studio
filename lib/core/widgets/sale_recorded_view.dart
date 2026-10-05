import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';
import '../money/money.dart';

/// What the mark-sold sheet turns into once the sale is saved.
///
/// **This is the app's peak moment, so it is not a snackbar.** A sale is the
/// thing every other screen exists to produce; a four-second toast over the
/// screen behind it was the whole reward. The check pops in, the price is set
/// large, and the timeline says what the sale still needs.
///
/// **It never shows a profit.** Nothing is estimated (hard rule 3), so until
/// a payout is recorded the last step says why the figure is not known yet
/// rather than printing one.
class SaleRecordedView extends StatelessWidget {
  const SaleRecordedView({
    required this.salePrice,
    required this.marketplaceName,
    required this.subject,
    required this.payoutRecorded,
    required this.onDone,
    super.key,
  });

  final Money salePrice;
  final String marketplaceName;

  /// The item's title, or the bundle's size.
  final String subject;

  final bool payoutRecorded;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(height: SdSpacingConstant.h8),
      const Center(child: _SoldBadge()),
      SizedBox(height: SdSpacingConstant.h16),
      Text(
        context.l10n.saleRecordedOn(marketplaceName),
        style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
          color: context.sdTheme3.profit,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: SdSpacingConstant.h4),
      Text(
        context.money(salePrice),
        style: context.textTheme3.headlineLarge!.tabular3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: SdSpacingConstant.h4),
      Text(
        subject,
        style: context.textTheme3.bodyMedium!.muted3(context),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: SdSpacingConstant.h24),
      _NextSteps(payoutRecorded: payoutRecorded),
      SizedBox(height: SdSpacingConstant.h24),
      SdButtonV3(
        variant: SdButtonVariantV3.primary,
        label: context.l10n.commonDone,
        expand: true,
        onPressed: onDone,
      ),
    ],
  );
}

/// The check, scaling in over a soft glow of the profit colour.
///
/// Still when the platform asks for reduced motion — the badge is the
/// message, the bounce is decoration.
class _SoldBadge extends StatelessWidget {
  const _SoldBadge();

  @override
  Widget build(BuildContext context) {
    final Color tint = context.sdTheme3.profit;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final double size = SdSpacingConstant.w56 + SdSpacingConstant.w20;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: still ? 1 : 0.6, end: 1),
      duration: still ? Duration.zero : SdMotionV3.slow,
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
        child: SdIconV3(
          AppIconConstant.check,
          size: SdSpacingConstant.w40,
          color: context.colorScheme3.onPrimary,
        ),
      ),
    );
  }
}

/// `Sold → Ship it → Record the payout`, the first already ticked.
class _NextSteps extends StatelessWidget {
  const _NextSteps({required this.payoutRecorded});

  final bool payoutRecorded;

  @override
  Widget build(BuildContext context) => Container(
    padding: SdContentPaddingV3.card,
    decoration: BoxDecoration(
      color: context.sdTheme3.surfaceSunken,
      borderRadius: SdRadiusV3.cardAll,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.saleRecordedNext,
          style: context.textTheme3.bodySmall!.semiBold3.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        _Step(
          icon: AppIconConstant.check,
          title: context.l10n.itemStatusSold,
          state: _StepState.done,
        ),
        _Step(
          icon: AppIconConstant.localShipping,
          title: context.l10n.orderShipIt,
          detail: context.l10n.saleRecordedShipDetail,
          state: _StepState.next,
        ),
        _Step(
          icon: payoutRecorded
              ? AppIconConstant.check
              : AppIconConstant.payments,
          title: payoutRecorded
              ? context.l10n.saleRecordedPayoutDone
              : context.l10n.saleRecordedPayoutStep,
          detail: payoutRecorded ? null : context.l10n.saleRecordedPayoutDetail,
          state: payoutRecorded ? _StepState.done : _StepState.later,
          isLast: true,
        ),
      ],
    ),
  );
}

enum _StepState { done, next, later }

/// One step: a disc on the rail, the title and its detail beside it.
class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.state,
    this.detail,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color done = context.sdTheme3.textSecondary;
    final Color faint = context.sdTheme3.textTertiary;
    final double disc = SdSpacingConstant.w28;
    final Color accent = switch (state) {
      _StepState.done => done,
      _StepState.next => context.sdTheme3.textPrimary,
      _StepState.later => faint,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: disc,
                height: disc,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == _StepState.done
                      ? done
                      : context.sdTheme3.surfaceElevated,
                  border: state == _StepState.done
                      ? null
                      : Border.all(color: accent, width: SdSpacingConstant.w2),
                ),
                child: SdIconV3(
                  icon,
                  size: SdSpacingConstant.w16,
                  color: state == _StepState.done
                      ? context.sdTheme3.surfaceElevated
                      : accent,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: SdSpacingConstant.w2,
                    constraints: BoxConstraints(
                      minHeight: SdSpacingConstant.h12,
                    ),
                    color: state == _StepState.done
                        ? done
                        : context.sdTheme3.border,
                  ),
                ),
            ],
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: SdSpacingConstant.h4,
                bottom: isLast ? 0 : SdSpacingConstant.h12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.textTheme3.bodyLarge!.semiBold3.copyWith(
                      color: state == _StepState.later
                          ? context.sdTheme3.textSecondary
                          : context.sdTheme3.textPrimary,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: context.textTheme3.bodySmall!.muted3(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
