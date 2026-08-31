import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/text_measure_utils.dart';
import '../../../domain/entities/plan_intro_offer.dart';
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
/// **Nine tenths of the screen, always.** A sheet that resized itself around
/// whatever the store returned read as a different screen on every open, and
/// the strip of page left above it is what says this one can be dismissed.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const double heightFactor = 0.9;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdBottomSheetV3(
    title: context.l10n.paywallTitle,
    closeTooltip: context.l10n.commonClose,
    heightFactor: heightFactor,
    child: Column(
      children: <Widget>[
        // Expanded, not Flexible: the content takes everything the footer does
        // not, which is what holds the links against the bottom edge when the
        // content is shorter than the sheet.
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SingleChildScrollView(
                  // - the column is at least the viewport, so the slack of a
                  //   90% sheet is real space to hand out
                  // - taller content overflows it and the view scrolls as usual
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      // Two groups, so the slack lands between them: what
                      // Premium includes stays under the title, the prices and
                      // the fine print sit against the footer.
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _PaywallBenefits(),

                        SizedBox(height: SdSpacingConstant.h12),
                        Column(
                          children: <Widget>[
                            const _PaywallOfferings(),
                            SizedBox(height: SdSpacingConstant.h16),
                            const _PaywallDisclosure(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        const _PaywallFooter(),
      ],
    ),
  );
}
