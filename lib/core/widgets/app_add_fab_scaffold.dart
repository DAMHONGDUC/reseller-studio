import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';

/// A scaffold whose create action is the button Inventory has.
///
/// **Owner's rule: every screen that creates something uses the same button,
/// in the same place.** Not an `IconButton` in the app bar, not a row at the
/// bottom of a list — the labelled `SdFabV3`. A create action a seller has to
/// hunt for is one they stop using.
///
/// **The button does not animate** — owner's rule. It keeps its label and its
/// place while the list scrolls and while the tab bar slides away, so it is
/// always where the thumb last found it.
///
/// [floatingNav] is true on the five tab screens and false everywhere else: a
/// pushed route has no glass bar under it, and the inset would leave the
/// button hovering above nothing.
class AppAddFabScaffold extends StatelessWidget {
  const AppAddFabScaffold({
    required this.body,
    this.appBar,
    required this.addLabel,
    required this.onAdd,
    this.floatingNav = false,
    this.bottomNavigationBar,
    this.showAdd = true,
    super.key,
  });

  /// Null when the screen draws its own chrome inside the body — Inventory
  /// does, because `SdSearchHeaderV3` is a sliver that has to live in the
  /// scroll view to dock as the list moves.
  final PreferredSizeWidget? appBar;

  final Widget body;

  /// What the button says. A verb and its object — "Add a category", not
  /// "Add": the label is the only thing telling a seller what they are about
  /// to create.
  final String addLabel;

  final VoidCallback onAdd;

  /// True on a tab screen, so the button clears the floating glass bar.
  final bool floatingNav;

  final Widget? bottomNavigationBar;

  /// Hides the button without unmounting the screen — for a bulk-selection
  /// mode, where two floating controls competing for one corner is how the
  /// wrong one gets tapped.
  final bool showAdd;

  /// Where the button's top edge sits, measured up from the bottom of the
  /// window.
  ///
  /// **Three terms, and dropping any one of them puts a row behind the
  /// button.** What the button itself clears — the glass bar on a tab screen,
  /// the device's safe area anywhere else — plus `Scaffold`'s own FAB margin,
  /// plus the button. That margin is the term this used to miss: `Scaffold`
  /// adds it whatever the caller does, so a clearance computed without it is
  /// short by exactly 16 and the last row of Expenses sat under the button.
  static double fabInset(BuildContext context, {bool floatingNav = false}) =>
      (floatingNav
          ? SdContentPaddingV3.floatingBarInset(context)
          : SdContentPaddingV3.detailBottom(context)) +
      kFloatingActionButtonMargin +
      SdFabV3.size;

  /// Screen padding with room for the button underneath it.
  ///
  /// Belongs here rather than at each call site: the button is this widget's
  /// doing, so the clearance it needs is too. Without it the last row of every
  /// list sits under the FAB and cannot be tapped — which only shows up when
  /// the list is long enough to scroll to the end.
  ///
  /// Clears the button and then leaves `bottomGap` above it, the same air the
  /// last row gets over the nav bar — owner's rule that no content is ever
  /// covered by the chrome at the bottom of the screen.
  static EdgeInsets listPadding(
    BuildContext context, {
    bool floatingNav = false,
  }) => SdContentPaddingV3.screen(context, floatingNav: floatingNav).copyWith(
    bottom:
        fabInset(context, floatingNav: floatingNav) +
        SdContentPaddingV3.bottomGap,
  );

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    appBar: appBar,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: showAdd
        ? Padding(
            // `extendBody` keeps the FAB in the body's coordinate space
            // rather than stacking it above the bottom slot, so without this
            // lift the button renders *behind* the glass on a tab screen.
            padding: EdgeInsets.only(
              bottom: floatingNav
                  ? SdContentPaddingV3.floatingBarInset(context)
                  : 0,
            ),
            child: SdFabV3(
              icon: AppIconConstant.add,
              label: addLabel,
              onPressed: onAdd,
            ),
          )
        : null,
    body: body,
  );
}
