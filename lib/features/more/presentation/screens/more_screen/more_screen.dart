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
import '../../../../../core/widgets/app_status_card.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../reseller_studio_app.dart';
import '../../../../app_config/providers.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/providers.dart';
import '../../../../subscription/domain/enums/seller_plan.dart';
import '../../../../subscription/providers.dart';
import '../../../../sync/domain/enums/sync_status.dart';
import '../../../../sync/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../more_constant.dart';
import '../../controllers/app_locale_controller.dart';
import '../../controllers/delete_all_data_controller.dart';
import '../../controllers/seed_data_controller.dart';
import '../../controllers/theme_mode_controller.dart';

part 'more_screen_account_actions.dart';
part 'more_screen_dev_rows.dart';
part 'more_screen_general_section.dart';
part 'more_screen_more_row.dart';
part 'more_screen_section.dart';
part 'more_screen_sync_status_card.dart';

/// More — "where do I manage everything else?".
///
/// Everything the plan deliberately kept off the bottom bar: Sourcing,
/// Listings, Expenses, Reports, Receipts, Categories, Locations,
/// Marketplaces, Carriers, Team (plan §10) — and what Settings held, since
/// there is no Settings screen (`lib/features/more/CLAUDE.md`).
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
    // Signed out, the rows a server writes are dropped (`MoreConstant.accountOnly`).
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
          _GeneralSection(signedIn: signedIn, plan: plan),
          for (final MoreSection section in sections)
            _MoreSection(section: section, plan: plan),
        ],
      ),
    );
  }
}
