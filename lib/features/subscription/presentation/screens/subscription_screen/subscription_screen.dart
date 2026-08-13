import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/plan_offering.dart';
import '../../../domain/entities/subscription_status.dart';
import '../../../domain/enums/seller_plan.dart';
import '../../../providers.dart';
import '../../controllers/subscription_controller.dart';
import '../../subscription_labels.dart';

part 'subscription_screen_current_card.dart';
part 'subscription_screen_offerings.dart';
part 'subscription_screen_plan_card.dart';

/// Subscription — what the seller is on, and what the other plans give
/// (plan §25's Subscription block, over §27's tiers).
///
/// **One screen, not a paywall and a settings page.** A seller who opens this
/// from More is asking the same question a blocked action asks on their
/// behalf: what do I have, and what would I get. Splitting that into two
/// screens means two places to keep the plan copy true.
///
/// Cancelling is deliberately not here: neither store lets an app cancel a
/// subscription, so the honest thing is to say where it is done rather than
/// draw a button that opens a browser and blames the user when it fails.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final SubscriptionStatus status = await ref
          .read(subscriptionControllerProvider.notifier)
          .restore();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(
        context,
        status.plan.isPaid
            ? '${SubscriptionLabels.name(status.plan)} restored'
            : 'Nothing to restore on this account',
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SellerPlan plan = ref.watch(currentPlanProvider);
    final SubscriptionStatus? status = ref
        .watch(subscriptionStatusProvider)
        .value;
    final bool isBusy = ref.watch(subscriptionControllerProvider);

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Subscription'),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          _CurrentPlanCard(plan: plan, status: status),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          const SdSectionHeaderV3(
            title: 'Plans',
            subtitle: 'Change any time — the store handles the proration',
            first: true,
          ),
          _Offerings(currentPlan: plan, isBusy: isBusy),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          AppListCard(
            children: <Widget>[
              AppListRow(
                title: 'Restore purchases',
                subtitle: 'If you already paid on another device',
                icon: Symbols.restore_rounded,
                showChevron: false,
                onTap: isBusy ? null : () => _restore(context, ref),
              ),
              if (status != null && status.source != SubscriptionSource.none)
                AppListRow(
                  title: 'Manage billing',
                  subtitle: _billingHome(status.source),
                  icon: Symbols.credit_card_rounded,
                  showChevron: false,
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            AppEnv.hasBillingConfig
                ? 'Your plan is tied to your store account, not to this '
                      'device. Signing in on another phone brings it with you.'
                : 'Billing is not set up in this build, so everything is on '
                      'the Free plan. Nothing here can be bought yet.',
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV3.bottomGap),
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
