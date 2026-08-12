import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/config/dev_flags.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';

/// The app widget.
///
/// **`ScreenUtilInit` sits above `MaterialApp` and is not optional.** Every
/// dimension in the design system resolves through `SdSpacingConstant`, whose
/// getters call screenutil at *runtime* — so without this in the tree, the
/// first `SdSpacingConstant.w16` a widget reads throws. A widget test that
/// pumps `SellerOsApp` gets it for free; one that pumps a bare `MaterialApp`
/// must install it by hand.
///
/// **It must be given `builder:`, never `child:`, and this is not a style
/// preference.** `AppTheme.light` reads `SdSpacingConstant.sp*` to build its
/// `TextTheme`, so the theme is itself a screenutil consumer. Passed as
/// `child:` it would be constructed as an argument — evaluated by *this*
/// build method, before `ScreenUtilInit` has initialized anything — and throw
/// `ScreenUtil not initialized`. `builder:` defers construction until after
/// init. `test/core/theme/app_theme_test.dart` fails if this is changed back.
///
/// [designSize] is the canvas every spacing number was chosen against. Change
/// it and every dimension in both the app and the design system rescales at
/// once, which is a thing to do deliberately and never to fix one screen.
class SellerOsApp extends ConsumerWidget {
  const SellerOsApp({super.key});

  /// iPhone 14 / 15 logical size — the device the layouts were drawn for.
  static const Size designSize = Size(390, 844);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      builder: (BuildContext context, Widget? child) => MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Follows the system until Settings ships its own theme control
        // (plan §25). That control writes to a provider watched here.
        themeMode: ThemeMode.system,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) =>
            _DevBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Marks a build whose authentication has been bypassed.
///
/// Wraps at `MaterialApp.builder`, so it covers every route including the
/// ones pushed over the shell — a marker that only appears on Home is a
/// marker you scroll past.
///
/// `DevFlags.bypassAuth` is a compile-time constant, so in a release build
/// this is `if (false)` and the tree-shaker removes both the branch and
/// [Banner] with it. The widget still sits in the tree in that case and costs
/// one pass-through build, which is the price of not writing two app widgets.
class _DevBanner extends StatelessWidget {
  const _DevBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!DevFlags.bypassAuth) return child;

    return Banner(
      message: 'AUTH OFF',
      location: BannerLocation.topEnd,
      color: AppColors.warning,
      child: child,
    );
  }
}
