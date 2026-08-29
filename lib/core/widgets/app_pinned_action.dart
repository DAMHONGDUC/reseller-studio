import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The commit button on an add or edit screen, holding the bottom edge.
///
/// **Owner's rule: every add or edit screen pins its save action.** Only the
/// fields scroll, so a seller never scrolls to find out how to finish and the
/// way to finish is in the same place on every screen. Three screens had
/// written their own before this was extracted, which is three chances for the
/// gap above the button to be a different number.
///
/// It sits **below** the scroll view, never over it, so content can never pass
/// behind it — which is why it wears no surface and no blur:
/// `SdContentPaddingV3.pinnedActionsGap` above is the whole separation and
/// `SdContentPaddingV3.bottom` below it clears the home indicator.
///
/// Small on purpose: a screen rebuilds this on every keystroke to keep
/// [onPressed] honest, and rebuilding a button is cheap in a way rebuilding a
/// form is not.
class AppPinnedAction extends StatelessWidget {
  const AppPinnedAction({
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    super.key,
  });

  final String label;

  /// Null disables the button — what a form with an unmet requirement passes.
  final VoidCallback? onPressed;

  final bool isBusy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      SdContentPaddingV3.horizontal,
      SdContentPaddingV3.pinnedActionsGap,
      SdContentPaddingV3.horizontal,
      SdContentPaddingV3.bottom(context),
    ),
    child: SdButtonV3(
      variant: SdButtonVariantV3.primary,
      label: label,
      expand: true,
      busy: isBusy,
      onPressed: onPressed,
    ),
  );
}
