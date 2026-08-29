import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/link_utils.dart';

/// The paywall's whole footer: restore, Terms of Use and Privacy Policy, as
/// one wrapping row of compact links.
///
/// **One row rather than a button stacked over a row.** These are the three
/// things a seller taps least, and the footer they used to occupy — a
/// full-width Restore button above two Material text buttons — cost a fifth of
/// the sheet. Nothing here scrolls away: App Store review needs both legal
/// destinations and a restore path reachable from the surface that sells.
class PaywallFooterLinks extends StatelessWidget {
  const PaywallFooterLinks({
    required this.termsUrl,
    required this.privacyUrl,
    required this.onRestore,
    this.isRestoring = false,
    super.key,
  });

  final String termsUrl;
  final String privacyUrl;
  final VoidCallback onRestore;

  /// Shows the restore link's spinner and blocks every link while the store
  /// is being asked — restoring navigates on success, so a second tap
  /// mid-flight has nowhere to land.
  final bool isRestoring;

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    if (context.mounted && !opened) {
      SdSnackBarUtilsV3.error(context, context.l10n.legalCouldNotOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> links = <Widget>[
      PaywallFooterLink(
        label: context.l10n.subscriptionRestorePurchases,
        busy: isRestoring,
        onPressed: onRestore,
      ),
      if (termsUrl.isNotEmpty)
        PaywallFooterLink(
          label: context.l10n.legalTermsOfUse,
          onPressed: () => _open(context, termsUrl),
        ),
      if (privacyUrl.isNotEmpty)
        PaywallFooterLink(
          label: context.l10n.legalPrivacyPolicy,
          onPressed: () => _open(context, privacyUrl),
        ),
    ];

    // Wrap, not Row: three labels at a large text scale do not fit one line on
    // a narrow phone, and a second line is better than three ellipses.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int index = 0; index < links.length; index++) ...<Widget>[
          if (index > 0) const PaywallFooterDot(),
          links[index],
        ],
      ],
    );
  }
}

/// One underlined link in the paywall's footer row.
///
/// **A [TextButton], not [SdButtonV3].** The design system's button is a
/// control with a fill, a border and a full-size padding on every variant; a
/// legal link is type with a rule under it, and dressing three of them as
/// buttons is what made the old footer read as an action bar. The Material
/// button is used only for its ink and focus handling, with its own minimum
/// size and tap-target padding taken off.
class PaywallFooterLink extends StatelessWidget {
  const PaywallFooterLink({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = context.textTheme3.bodySmall!.copyWith(
      color: context.sdTheme3.textSecondary,
      decoration: TextDecoration.underline,
    );

    return TextButton(
      onPressed: busy ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w8,
          vertical: SdSpacingConstant.h10,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (busy) ...<Widget>[
            SdLoadingV3(
              size: SdLoadingV3.inlineSize,
              color: context.sdTheme3.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w6),
          ],
          Flexible(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The separator between two footer links. Decorative, so it says nothing to
/// a screen reader walking the row.
class PaywallFooterDot extends StatelessWidget {
  const PaywallFooterDot({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      '•',
      style: context.textTheme3.bodySmall!.copyWith(
        color: context.sdTheme3.textTertiary,
      ),
    ),
  );
}
