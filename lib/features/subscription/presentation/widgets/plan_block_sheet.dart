import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/enums/seller_plan.dart';
import '../../domain/services/plan_gate.dart';
import '../subscription_labels.dart';

/// What a seller sees the moment a plan limit stops them.
///
/// **It names the ceiling and offers the way past it, in that order.** A
/// blocked action that says only "upgrade" makes the seller work out what
/// they did wrong; naming the limit is what turns a refusal into a decision.
///
/// A sheet rather than a screen: the seller was in the middle of something,
/// and a full-screen paywall over a half-typed form loses their place.
class PlanBlockSheet extends ConsumerWidget {
  const PlanBlockSheet._({required this.block, required this.plan});

  final PlanBlock block;
  final SellerPlan plan;

  /// Shows the sheet, or does nothing when [block] is [PlanBlock.none].
  ///
  /// Returning early on `none` is what lets every call site be written as
  /// "check, then show" without an `if` around it.
  static Future<void> show(
    BuildContext context, {
    required PlanBlock block,
    required SellerPlan plan,
  }) {
    if (block == PlanBlock.none) return Future<void>.value();

    AppLogger.action('Paywall shown', <String, String>{
      'reason': SubscriptionLabels.blockKey(block),
      'fromPlan': plan.name,
    });
    AppAnalytics.instance.paywallShown(
      reason: SubscriptionLabels.blockKey(block),
      fromPlan: plan.name,
    );

    return showSdBottomSheetV3<void>(
      context: context,
      builder: (BuildContext _) => PlanBlockSheet._(block: block, plan: plan),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SellerPlan? target = PlanGate.upgradeFor(block, from: plan);

    return SdBottomSheetV3(
      title: 'Upgrade to continue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            SubscriptionLabels.blockReason(block, plan),
            style: context.textTheme3.bodyMedium!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          if (target != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h16),
            for (final String line in SubscriptionLabels.allowances(target))
              Padding(
                padding: EdgeInsets.only(bottom: SdSpacingConstant.h4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SdIconV3(
                      Symbols.check_rounded,
                      size: SdIconV3.smallSize,
                      color: context.sdTheme3.success,
                    ),
                    SizedBox(width: SdSpacingConstant.w8),
                    Expanded(
                      child: Text(
                        line,
                        style: context.textTheme3.bodyMedium!.copyWith(
                          color: context.sdTheme3.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          SizedBox(height: SdSpacingConstant.h20),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: target == null
                ? 'See plans'
                : 'See ${SubscriptionLabels.name(target)}',
            expand: true,
            onPressed: () {
              // Pop first: leaving the sheet up behind a pushed screen means
              // the seller comes back to a sheet they already dealt with.
              Navigator.of(context).pop();
              context.push(AppRoutes.subscription);
            },
          ),
          SizedBox(height: SdSpacingConstant.h8),
          SdButtonV3(
            variant: SdButtonVariantV3.text,
            label: 'Not now',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
