import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../domain/entities/subscription_status.dart';
import '../../../domain/enums/seller_plan.dart';
import '../../../providers.dart';
import '../../subscription_labels.dart';

part 'subscription_screen_current_card.dart';

/// Subscription — what the seller is on, and what the other plans give
/// (plan §25's Subscription block, over §27's Free/Premium model).
///
/// This screen manages an existing relationship with the store. Buying lives
/// on `PaywallScreen`, whose route is presented as a bottom sheet.
///
/// Cancelling is deliberately not here: neither store lets an app cancel a
/// subscription, so the honest thing is to say where it is done rather than
/// draw a button that opens a browser and blames the user when it fails.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SellerPlan plan = ref.watch(currentPlanProvider);
    final SubscriptionStatus? status = ref
        .watch(subscriptionStatusProvider)
        .value;

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.moreSubscription),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              // No bottom inset when the action is pinned: it owns that edge.
              padding: plan.isPaid
                  ? SdContentPaddingV3.screen(context)
                  : EdgeInsets.symmetric(
                      horizontal: SdContentPaddingV3.horizontal,
                    ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                _CurrentPlanCard(plan: plan, status: status),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                if (status != null && status.source != SubscriptionSource.none)
                  AppListCard(
                    children: <Widget>[
                      AppListRow(
                        title: context.l10n.subscriptionManageBilling,
                        subtitle: _billingHome(status.source),
                        icon: AppIconConstant.creditCard,
                        showChevron: false,
                      ),
                    ],
                  ),
                SizedBox(height: SdContentPaddingV3.bottomGap),
              ],
            ),
          ),
          // Gone rather than disabled for a paying seller: there is nothing
          // left to buy, and the card above already says which plan is theirs.
          if (!plan.isPaid)
            AppPinnedAction(
              label: context.l10n.subscriptionViewPremiumPlans,
              onPressed: () => context.push(AppRoutes.paywall),
            ),
        ],
      ),
    );
  }

  /// Where a subscription is actually cancelled. Named rather than linked:
  /// the deep link differs by OS version and a dead link in a billing screen
  /// is the worst place to have one.
  static String _billingHome(SubscriptionSource source) => switch (source) {
    SubscriptionSource.appStore => 'Settings → your name → Subscriptions',
    SubscriptionSource.playStore => 'Play Store → Payments → Subscriptions',
    SubscriptionSource.promotional => 'Granted directly — no billing attached',
    SubscriptionSource.none => '',
  };
}
