part of 'paywall_screen.dart';

/// The fine print, in the smallest type on the sheet: what the seller is
/// joining, and that it renews until they cancel (App Store guideline 3.1.2
/// requires the second in the binary).
class _PaywallDisclosure extends StatelessWidget {
  const _PaywallDisclosure();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = context.textTheme3.bodySmall!.copyWith(
      color: context.sdTheme3.textTertiary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.paywallStoreAccountNote, style: style),
        SizedBox(height: SdSpacingConstant.h6),
        Text(context.l10n.subscriptionRenewalTerms, style: style),
      ],
    );
  }
}
