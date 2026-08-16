part of 'onboarding_screen.dart';

/// One intro page: a glyph, a headline, a sentence.
///
/// Centred and driven entirely by its [AppFeature], so adding a fourth page is
/// a list entry and two ARB keys rather than another layout to keep in step
/// with these three. The login screen renders the same three compactly.
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final AppFeature page;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: SdSpacingConstant.r88,
            height: SdSpacingConstant.r88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // The same wash `SdIconTileV3` puts behind a row glyph, read
              // from it rather than retyped, so the two never drift.
              color: accent.withValues(alpha: SdIconTileV3.backgroundOpacity),
              shape: BoxShape.circle,
            ),
            child: SdIconV3(
              page.icon,
              size: SdSpacingConstant.r44,
              color: accent,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.textTheme3.headlineSmall!.bold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ],
      ),
    );
  }
}
