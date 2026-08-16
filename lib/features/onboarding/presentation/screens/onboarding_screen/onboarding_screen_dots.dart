part of 'onboarding_screen.dart';

/// Which page of how many, as dots.
///
/// The active dot stretches rather than only changing colour — **colour is
/// never the only signal** (`docs/rules/DESIGN_SYSTEM.md`), and a row of dots
/// distinguished by hue alone is unreadable to a colour-blind seller.
///
/// The dots carry no meaning to a screen reader on their own, so the row
/// announces its position as one label instead.
class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double dot = SdSpacingConstant.r8;

    return Semantics(
      label: context.l10n.onboardingPageSemantics(index + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < count; i++)
              AnimatedContainer(
                duration: SdMotionV3.normal,
                curve: SdMotionV3.standard,
                margin: EdgeInsets.symmetric(
                  horizontal: SdSpacingConstant.w4,
                ),
                height: dot,
                width: i == index ? SdSpacingConstant.w24 : dot,
                decoration: BoxDecoration(
                  color: i == index
                      ? context.colorScheme3.primary
                      : context.sdTheme3.border,
                  borderRadius: BorderRadius.circular(SdSpacingConstant.r999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
