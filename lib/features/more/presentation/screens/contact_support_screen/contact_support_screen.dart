import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_pinned_action.dart';

/// Contact support — the address in full, and one button that writes to it.
///
/// The address is shown before anything opens so a seller with no mail app
/// set up can still copy it by hand.
class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _send(BuildContext context) async {
    final String address = AppEnv.contactEmailSupport;
    final bool opened = await LinkUtils.open(LinkUtils.mailto(address));

    // LinkUtils already logged the failure; this only tells the seller.
    if (context.mounted && !opened) {
      SdSnackBarUtilsV3.error(
        context,
        context.l10n.moreContactSupportFailed(address),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool configured = AppEnv.hasSupportEmail;

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.moreContactSupport),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Text(
            context.l10n.contactSupportIntro,
            style: context.textTheme3.bodyMedium!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          AppListCard(
            children: <Widget>[
              AppListRow(
                title: context.l10n.contactSupportEmail,
                // Reached by a deep link with no address configured: a dash,
                // never a blank (hard rule 5).
                subtitle: configured ? AppEnv.contactEmailSupport : '—',
                icon: AppIconConstant.mail,
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppPinnedAction(
        label: context.l10n.contactSupportSend,
        icon: AppIconConstant.mail,
        onPressed: configured ? () => _send(context) : null,
      ),
    );
  }
}
