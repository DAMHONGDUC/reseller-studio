import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/subscription/domain/entities/subscription_status.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

List<Override> premiumSubscription() => <Override>[
  subscriptionStatusProvider.overrideWith(
    (Ref ref) => Stream<SubscriptionStatus>.value(
      const SubscriptionStatus(
        plan: SellerPlan.premium,
        source: SubscriptionSource.appStore,
      ),
    ),
  ),
];
