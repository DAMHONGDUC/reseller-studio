part of 'paywall_screen.dart';

/// What Premium gives, in two columns under its tagline.
///
/// **Two columns, not nine rows.** The allowances and the features together
/// are nine lines, and stacked they were most of the sheet's height — the
/// seller is scanning what they get, not reading it.
class _PaywallBenefits extends StatelessWidget {
  const _PaywallBenefits();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        SubscriptionLabels.tagline(SellerPlan.premium),
        style: context.textTheme3.bodyMedium!.copyWith(
          color: context.sdTheme3.textSecondary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h12),
      // A well, not a raised card: this is the thing being bought, read and
      // never tapped, so the option cards below it own the sheet's one raised
      // depth.
      SdCardV3(
        layer: SdCardLayerV3.sunken,
        padding: EdgeInsets.all(SdSpacingConstant.w12),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double columnWidth =
                (constraints.maxWidth - SdSpacingConstant.w12) / 2;

            return Wrap(
              spacing: SdSpacingConstant.w12,
              runSpacing: SdSpacingConstant.h8,
              children: <Widget>[
                for (final String line in SubscriptionLabels.allowances(
                  SellerPlan.premium,
                ))
                  SizedBox(
                    width: columnWidth,
                    child: _PaywallBenefitLine(label: line),
                  ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class _PaywallBenefitLine extends StatelessWidget {
  const _PaywallBenefitLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SdIconV3(
        AppIconConstant.check,
        size: SdIconV3.smallSize,
        color: context.sdTheme3.success,
      ),
      SizedBox(width: SdSpacingConstant.w6),
      Expanded(
        child: Text(
          label,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ),
    ],
  );
}
