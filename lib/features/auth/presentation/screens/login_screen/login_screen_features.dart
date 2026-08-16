part of 'login_screen.dart';

/// What the app does, as three rows.
///
/// The same three the intro flow gives full pages to — one list, two screens
/// (`AppFeatureConstant`). Compact here because they sit above the buttons
/// rather than being the whole screen.
class _LoginFeatures extends StatelessWidget {
  const _LoginFeatures();

  @override
  Widget build(BuildContext context) {
    final List<AppFeature> features = AppFeatureConstant.of(context);

    return Column(
      children: <Widget>[
        for (final AppFeature feature in features) ...<Widget>[
          _LoginFeatureRow(feature: feature),
          if (feature != features.last)
            SizedBox(height: SdContentPaddingV3.listItemGap),
        ],
      ],
    );
  }
}

/// One feature: a tinted glyph, a claim, and the sentence that backs it.
///
/// **No card.** Three cards stacked would be three boxes competing with the
/// two buttons underneath, and the buttons are what this screen is for — one
/// loud element per screen (`docs/rules/DESIGN_SYSTEM.md`).
class _LoginFeatureRow extends StatelessWidget {
  const _LoginFeatureRow({required this.feature});

  final AppFeature feature;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SdIconTileV3(
        icon: feature.icon,
        tint: context.colorScheme3.primary,
      ),
      SizedBox(width: SdSpacingConstant.w12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              feature.title,
              style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h2),
            Text(
              feature.body,
              style: context.textTheme3.bodySmall!.muted3(context),
            ),
          ],
        ),
      ),
    ],
  );
}
