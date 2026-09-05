import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../providers.dart';

/// The one screen a seller cannot leave.
///
/// **No app bar, no back, no tabs.** Every other route in the app is reachable
/// from somewhere; this one exists because the binary cannot be trusted to
/// talk to the backend any more, so leaving it is the one thing it must not
/// offer. The router sends every location here while
/// `forceUpdateProvider` says so, which is what makes the block hold rather
/// than this screen refusing a pop.
///
/// **The button is absent when the config names no link**, rather than drawn
/// and dead: a forced-update screen with a button that does nothing is worse
/// than one that just says what happened, because the seller taps it twice and
/// concludes the app is broken instead of old.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    if (opened || !context.mounted) return;

    SdSnackBarUtilsV3.error(context, context.l10n.updateRequiredFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? url = ref.watch(updateUrlProvider);

    return SdScaffoldV3(
      body: SdEmptyStateV3(
        icon: AppIconConstant.systemUpdate,
        title: context.l10n.updateRequiredTitle,
        message: context.l10n.updateRequiredBody,
        action: url == null
            ? null
            : SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.updateRequiredAction,
                onPressed: () => _open(context, url),
              ),
      ),
    );
  }
}
