import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';

/// What the two fees are, and which one the app is using.
///
/// **They share a word and they are not the same thing** — owner's rule. The
/// platform fee is what this sale was actually charged and the only fee this
/// app stores; the marketplace rate is a percentage the seller sets, used only
/// to estimate a sale nobody has entered a fee for. A seller who cannot tell
/// them apart either leaves the box empty forever or types the estimate back
/// into it as though the platform had reported it.
///
/// **It ends on the way to the rate.** A sentence saying where a number lives
/// is worth less than the button that goes there.
class FeeExplainerSheet extends StatelessWidget {
  const FeeExplainerSheet._();

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext _) => const FeeExplainerSheet._(),
  );

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: context.l10n.feeExplainerTitle,
    closeTooltip: context.l10n.commonClose,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FeeBlock(
          icon: AppIconConstant.payments,
          title: context.l10n.feeExplainerPlatformTitle,
          body: context.l10n.feeExplainerPlatformBody,
        ),
        SizedBox(height: SdSpacingConstant.h16),
        _FeeBlock(
          icon: AppIconConstant.priceChange,
          title: context.l10n.feeExplainerRateTitle,
          body: context.l10n.feeExplainerRateBody,
        ),
        SizedBox(height: SdSpacingConstant.h16),
        Text(
          context.l10n.feeExplainerNote,
          style: context.textTheme3.bodySmall!.faint3(context),
        ),
        SizedBox(height: SdSpacingConstant.h20),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.feeExplainerOpenMarketplaces,
          expand: true,
          onPressed: () {
            // Pop first: leaving the sheet up behind a pushed screen means the
            // seller comes back to one they already dealt with.
            Navigator.of(context).pop();
            context.push(AppRoutes.marketplaces);
          },
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.text,
          label: context.l10n.commonClose,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// One of the two fees: its glyph, its name and what it means.
class _FeeBlock extends StatelessWidget {
  const _FeeBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SdIconV3(icon, color: context.colorScheme3.primary),
      SizedBox(width: SdSpacingConstant.w12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              body,
              style: context.textTheme3.bodySmall!.copyWith(
                color: context.sdTheme3.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
