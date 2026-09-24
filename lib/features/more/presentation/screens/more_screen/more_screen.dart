import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_row_chevron.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../app_config/providers.dart';
import '../../../../auth/providers.dart';
import '../../../../subscription/domain/enums/seller_plan.dart';
import '../../../../subscription/providers.dart';
import '../../../../sync/domain/enums/sync_status.dart';
import '../../../../sync/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../more_constant.dart';
import '../../controllers/delete_all_data_controller.dart';
import '../../controllers/seed_data_controller.dart';

part 'more_screen_delete_all_data_card.dart';
part 'more_screen_developer_section.dart';
part 'more_screen_more_row.dart';
part 'more_screen_section.dart';
part 'more_screen_seed_data_card.dart';
part 'more_screen_sync_status_card.dart';

/// More — "where do I manage everything else?".
///
/// Everything the plan deliberately kept off the bottom bar: Sourcing,
/// Listings, Expenses, Reports, Receipts, Categories, Locations,
/// Marketplaces, Carriers, Team, Settings (plan §10).
///
/// **This screen growing is fine. The bottom bar growing is not** — five tabs
/// is a product decision (hard rule 13), and this list is where the pressure
/// to add a sixth goes instead.
///
/// Destinations with no screen yet are rendered as disabled rows rather than
/// hidden. Hiding them would make the app look finished; showing them greyed
/// says what is coming and stops a tap leading nowhere.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.watch(isSignedInProvider) ?? false;
    // Signed out, every other destination is a view onto a business that has
    // not been named yet — so the list is Settings alone rather than eleven
    // rows that all bounce back here (owner's rule).
    final List<MoreSection> sections = MoreConstant.sectionsFor(
      signedIn: signedIn,
    );
    final SellerPlan plan = ref.watch(currentPlanProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.navMore),
      body: ListView(
        padding: SdContentPaddingV3.screen(context, floatingNav: true),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _SyncStatusCard(),
          for (final MoreSection section in sections)
            _MoreSection(section: section, plan: plan, signedIn: signedIn),
          const _DeveloperSection(),
        ],
      ),
    );
  }
}
