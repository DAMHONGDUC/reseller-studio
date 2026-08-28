part of 'home_screen.dart';

/// What Needs Attention says to a business that has never held anything.
///
/// **It replaces `_AllClear`, it does not sit beside it.** "All clear" is a
/// report on work that exists; on a new account there is no work, and the
/// report was reading as reassurance the seller had not earned. One card
/// answers the section, so the two cannot both be on screen claiming
/// different things.
///
/// It disappears the moment the first item or order lands — see
/// `workspaceActivityProvider`. Nothing to dismiss, nothing to remember.
class _StartHere extends StatelessWidget {
  const _StartHere();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdIconTileV3(
              icon: Symbols.rocket_launch_rounded,
              tint: context.colorScheme3.primary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.homeStartHereTitle,
                    style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                  Text(
                    context.l10n.homeStartHereBody,
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.quickAddTitle,
          icon: Symbols.bolt_rounded,
          expand: true,
          // Pushed, like every other Home hand-off: the screen that owns the
          // record owns the form (see this feature's CLAUDE.md).
          onPressed: () => context.push(AppRoutes.quickAdd),
        ),
      ],
    ),
  );
}
