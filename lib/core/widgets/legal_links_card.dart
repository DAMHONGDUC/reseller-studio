import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../config/app_env.dart';
import '../extensions/context_extensions.dart';
import '../utils/link_utils.dart';
import 'app_list_row.dart';

/// The privacy policy and the terms, as two rows that open a browser.
///
/// **App Store review requires both to be reachable from inside the binary**
/// — guideline 3.1.2 for a subscription, 5.1.1 for an app that creates
/// accounts — which is why this sits on the paywall and on About rather than
/// only in the store listing. In `core/widgets/` because two features draw it
/// and the second copy is the trigger.
///
/// The addresses come from `AppEnv` (owner's rule, `docs/rules/ENV.md`), and
/// **a row with no address is not drawn**: a link to a 404 is a worse review
/// outcome than a missing one, because the reviewer clicks it.
class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    // The failure is already logged inside LinkUtils; this only tells the
    // seller why nothing happened.
    if (context.mounted && !opened) {
      SdSnackBarUtilsV3.error(context, context.l10n.legalCouldNotOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.hasLegalLinks) {
      return const SizedBox.shrink();
    }

    return AppListCard(
      children: <Widget>[
        if (AppEnv.termsOfServiceUrl.isNotEmpty)
          AppListRow(
            title: context.l10n.legalTermsOfUse,
            subtitle: context.l10n.legalTermsOfUseNote,
            icon: Symbols.gavel_rounded,
            showChevron: false,
            trailing: const SdIconV3(Symbols.open_in_new_rounded),
            onTap: () => _open(context, AppEnv.termsOfServiceUrl),
          ),
        if (AppEnv.privacyPolicyUrl.isNotEmpty)
          AppListRow(
            title: context.l10n.legalPrivacyPolicy,
            subtitle: context.l10n.legalPrivacyPolicyNote,
            icon: Symbols.shield_rounded,
            showChevron: false,
            trailing: const SdIconV3(Symbols.open_in_new_rounded),
            onTap: () => _open(context, AppEnv.privacyPolicyUrl),
          ),
      ],
    );
  }
}
