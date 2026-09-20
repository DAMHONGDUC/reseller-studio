import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:system_design/index.dart';

/// `ScreenUtilInit` with the clamp that stops a tablet scaling every token.
///
/// **The one place the app builds a `ScreenUtilInit`, and that is the rule
/// rather than a convenience.** screenutil resolves every dimension in the
/// design system by dividing the window by [designSize], so a second one
/// built by hand — in the app or in a test — is a tree rendering at a scale
/// nothing else in the app uses, and it would be the tree that never sees the
/// bug. `SdScreenScale` holds the clamp itself; this widget is what makes it
/// unavoidable.
///
/// **`minTextAdapt` is deliberately not passed.** `ScreenUtilInit` defaults
/// `fontSizeResolver` to `FontSizeResolvers.width`, and a resolver is
/// consulted before the flag is — so the flag decided nothing while reading
/// as though type followed a different ladder from the rest of the app. Type
/// takes the width ratio, which `SdScreenScale` clamps alongside the other
/// three.
///
/// **It must give `builder:`, never `child:`.** `AppTheme.light` reads
/// `SdSpacingConstant.sp*` to build its `TextTheme`, so the theme is itself a
/// screenutil consumer: passed as `child:` it would be constructed as an
/// argument, before init has run, and throw `ScreenUtil not initialized`.
/// `test/core/theme/app_theme_test.dart` fails if that is changed back.
///
/// **The window is read through a `MediaQuery`, not off the view.** The
/// design size is an argument computed by *this* build, so this widget has to
/// rebuild when the window changes size — which a view read would not do, and
/// iPadOS Split View and Stage Manager change it while the app is running.
class AppScreenUtil extends StatelessWidget {
  const AppScreenUtil({required this.builder, super.key});

  /// iPhone 14 / 15 logical size — the canvas every spacing number in the app
  /// and the design system was chosen against.
  ///
  /// Change it and every dimension in both rescales at once, which is a thing
  /// to do deliberately and never to fix one screen.
  static const Size designSize = Size(390, 844);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => MediaQuery.fromView(
    view: View.of(context),
    child: Builder(
      builder: (BuildContext context) => ScreenUtilInit(
        designSize: SdScreenScale.designSize(
          MediaQuery.sizeOf(context),
          designSize,
        ),
        splitScreenMode: true,
        builder: (BuildContext context, Widget? _) => builder(context),
      ),
    ),
  );
}
