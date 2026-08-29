import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/plan_offering.dart';
import '../../../domain/entities/subscription_status.dart';
import '../../../domain/enums/seller_plan.dart';
import '../../../domain/services/plan_offering_catalogue.dart';
import '../../../providers.dart';
import '../../controllers/paywall_selection_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../subscription_labels.dart';
import '../../widgets/paywall_footer_links.dart';

part 'paywall_screen_benefits.dart';
part 'paywall_screen_offerings.dart';
part 'paywall_screen_plan_options.dart';
part 'paywall_screen_disclosure.dart';
part 'paywall_screen_footer.dart';

/// The only surface that sells Premium.
///
/// GoRouter owns this as a route, while [SdBottomSheetV3] gives the route its
/// modal presentation. Dismissing it therefore preserves the screen beneath.
///
/// **No height fraction.** What the sheet holds is a tagline, two columns of
/// benefits, two option cards and a button; a sheet fixed at nine tenths of
/// the screen spent the difference on dead space above the footer.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdBottomSheetV3(
    title: context.l10n.paywallTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Loose: the sheet is as tall as its content, and the content still
        // scrolls when a large text scale makes it taller than the screen.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _PaywallBenefits(),
                SizedBox(height: SdSpacingConstant.h16),
                const _PaywallOfferings(),
                SizedBox(height: SdSpacingConstant.h12),
                const _PaywallDisclosure(),
              ],
            ),
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        const _PaywallFooter(),
      ],
    ),
  );
}
