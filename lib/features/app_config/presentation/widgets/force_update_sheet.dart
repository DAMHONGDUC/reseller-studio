import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/link_utils.dart';
import '../../domain/entities/app_update_policy.dart';
import '../../providers.dart';

/// What a seller sees when their build is too old to run.
///
/// **A sheet nothing dismisses, not a screen.** Owner's rule. It is raised
/// over whatever the app was showing, so the seller keeps the context they
/// were in and there is no route to redirect to, no back stack to unwind and
/// no dead end left behind once the config is corrected. What holds the block
/// is `SdBottomSheetExitV3.blocked` — no close button, no handle, no barrier
/// tap, no back gesture.
///
/// **The button is absent when the config names no link**, rather than drawn
/// and dead: a forced-update prompt with a button that does nothing is worse
/// than one that just says what happened, because the seller taps it twice and
/// concludes the app is broken instead of old.
class ForceUpdateSheet extends ConsumerWidget {
  const ForceUpdateSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showSdBottomSheetV3<void>(
        context: context,
        exit: SdBottomSheetExitV3.blocked,
        builder: (BuildContext context) => const ForceUpdateSheet(),
      );

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    if (opened || !context.mounted) return;

    SdSnackBarUtilsV3.error(context, context.l10n.updateRequiredFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUpdatePolicy policy = ref.watch(currentUpdatePolicyProvider);
    final String? link = policy.storeLink;
    final String? version = policy.buildName;

    return SdBottomSheetV3(
      title: context.l10n.updateRequiredTitle,
      // Null on purpose: a blocked sheet draws no close button, and a tooltip
      // for a control that is not there is a string nobody can read.
      closeTooltip: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdIconV3(
            AppIconConstant.systemUpdate,
            size: SdSpacingConstant.r44,
            color: context.sdTheme3.textSecondary,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.updateRequiredBody,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
          if (version != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              context.l10n.updateRequiredVersion(version),
              style: context.textTheme3.bodySmall!.muted3(context),
            ),
          ],
          if (link != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.updateRequiredAction,
              expand: true,
              onPressed: () => _open(context, link),
            ),
          ],
        ],
      ),
    );
  }
}
