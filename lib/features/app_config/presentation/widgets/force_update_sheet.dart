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
/// **A sheet nothing dismisses, not a screen.** Owner's rule. It is drawn
/// over whatever the app was showing, so the seller keeps the context they
/// were in and there is no route to redirect to, no back stack to unwind and
/// no dead end left behind once the config is corrected. What holds the block
/// is `SdBottomSheetExitV3.blocked` — no close button, no handle, no barrier
/// tap, no back gesture.
///
/// **It is not presented as a route, and that is the point** — see
/// `ForceUpdateBlock`, which places it. This widget is only the panel.
///
/// **The button is absent when the config names no link**, rather than drawn
/// and dead: a forced-update prompt with a button that does nothing is worse
/// than one that just says what happened, because the seller taps it twice and
/// concludes the app is broken instead of old.
class ForceUpdateSheet extends ConsumerWidget {
  const ForceUpdateSheet({super.key});

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
          SizedBox(height: SdSpacingConstant.h8),
          // Filled, and it is the only filled tile on the panel: this sheet
          // has one thing to say and nothing else competing to be read first.
          SdIconTileV3(
            icon: AppIconConstant.systemUpdate,
            tint: context.colorScheme3.primary,
            size: SdIconTileSizeV3.large,
            filled: true,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.updateRequiredBody,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
          if (version != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h16),
            _ForceUpdateVersionCard(version: version),
          ],
          if (link != null) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.updateRequiredAction,
              icon: AppIconConstant.download,
              size: SdButtonSizeV3.large,
              expand: true,
              onPressed: () => _open(context, link),
            ),
          ],
        ],
      ),
    );
  }
}

/// The version the store is on, as a row of its own rather than a fourth
/// muted sentence.
///
/// It is the one concrete fact on the panel — the seller checks it against
/// what About shows them — so it gets a surface and a mark instead of
/// dissolving into the paragraph above it.
class _ForceUpdateVersionCard extends StatelessWidget {
  const _ForceUpdateVersionCard({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) => SdCardV3(
    layer: SdCardLayerV3.sunken,
    padding: SdContentPaddingV3.row,
    child: Row(
      children: <Widget>[
        SdIconV3(
          AppIconConstant.download,
          size: SdIconV3.smallSize,
          color: context.colorScheme3.primary,
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Expanded(
          child: Text(
            context.l10n.updateRequiredVersion(version),
            style: context.textTheme3.bodySmall!.semiBold3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
