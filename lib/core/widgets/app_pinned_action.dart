import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// A screen's own action, holding the bottom edge.
///
/// **Owner's rule: a screen with content and an action button pins that
/// button.** Only the content scrolls, so a seller never scrolls to find out
/// how to finish and the way to finish is in the same place on every screen.
/// Three screens had written their own before this was extracted, which is
/// three chances for the gap above the button to be a different number.
///
/// The line between a screen's action and a row's is drawn in
/// `docs/rules/SCREENS.md`; a button that acts on one record stays on it.
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
    this.variant = SdButtonVariantV3.primary,
    this.icon,
    this.isBusy = false,
    this.secondary,
    super.key,
  });

  final String label;

  /// The only thing a screen chooses here. The geometry is not negotiable —
  /// that is the whole reason this widget exists.
  final SdButtonVariantV3 variant;

  final IconData? icon;

  /// Null disables the button — what a form with an unmet requirement passes.
  final VoidCallback? onPressed;

  final bool isBusy;

  /// A second action stacked **above** the main one, sharing this slot's one
  /// bottom inset — a destructive verb on the record the screen is about, the
  /// shape Business details wears.
  ///
  /// - lowest is the primary, so the button under the resting thumb is always
  ///   the one the screen is for
  /// - a widget rather than a second set of label and variant props: there is
  ///   one of these in the app, and a config surface would outnumber its users
  /// - it carries its own gap below itself, because it is usually conditional
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      SdContentPaddingV3.horizontal,
      SdContentPaddingV3.pinnedActionsGap,
      SdContentPaddingV3.horizontal,
      SdContentPaddingV3.bottom(context),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?secondary,
        SdButtonV3(
          variant: variant,
          label: label,
          icon: icon,
          expand: true,
          busy: isBusy,
          onPressed: onPressed,
        ),
      ],
    ),
  );
}
