part of 'login_screen.dart';

/// The mark, the name and the line that says what the app is for.
///
/// The glyph wears the same tinted circle the intro flow gives each of its
/// pages, so arriving here from onboarding reads as the same product rather
/// than a second one.
///
/// **Left-aligned, not centred.** The three feature rows below it are
/// left-aligned because they are a list, and a centred block sitting on top of
/// a left-aligned one is the most common way a screen looks assembled rather
/// than designed.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: SdSpacingConstant.r64,
          height: SdSpacingConstant.r64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The wash `SdIconTileV3` puts behind a glyph, read from it rather
            // than retyped so the two never drift.
            color: accent.withValues(alpha: SdIconTileV3.backgroundOpacity),
            shape: BoxShape.circle,
          ),
          child: SdIconV3(
            Symbols.storefront_rounded,
            size: SdSpacingConstant.r36,
            color: accent,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h20),
        Text(
          context.l10n.appTitle,
          style: context.textTheme3.headlineMedium!.bold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          context.l10n.authTagline,
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
      ],
    );
  }
}
