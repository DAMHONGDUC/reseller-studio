import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/legal_links_card.dart';
import '../../../domain/entities/plan_offering.dart';
import '../../../domain/entities/subscription_status.dart';
import '../../../domain/enums/seller_plan.dart';
import '../../controllers/subscription_controller.dart';
import '../../subscription_labels.dart';

part 'paywall_screen_offerings.dart';
part 'paywall_screen_plan_card.dart';

/// The only surface that sells Premium.
///
/// GoRouter owns this as a route, while [SdBottomSheetV3] gives the route its
/// modal presentation. Dismissing it therefore preserves the screen beneath.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const double heightFactor = 0.9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBusy = ref.watch(subscriptionControllerProvider);

    return SdBottomSheetV3(
      title: context.l10n.paywallTitle,
      heightFactor: heightFactor,
      child: ListView(
        children: <Widget>[
          _PaywallOfferings(isBusy: isBusy),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            AppEnv.hasBillingConfig
                ? context.l10n.paywallStoreAccountNote
                : context.l10n.paywallUnavailable,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            context.l10n.subscriptionRenewalTerms,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SdSectionHeaderV3(title: context.l10n.legalSection),
          const LegalLinksCard(),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }
}
