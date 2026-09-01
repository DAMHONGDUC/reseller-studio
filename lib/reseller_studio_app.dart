import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/providers.dart';
import 'features/settings/presentation/controllers/theme_mode_controller.dart';
import 'l10n/gen/app_localizations.dart';

/// The app widget.
///
/// **`ScreenUtilInit` sits above `MaterialApp` and is not optional.** Every
/// dimension in the design system resolves through `SdSpacingConstant`, whose
/// getters call screenutil at *runtime* — so without this in the tree, the
/// first `SdSpacingConstant.w16` a widget reads throws. A widget test that
/// pumps `ResellerStudioApp` gets it for free; one that pumps a bare `MaterialApp`
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
class ResellerStudioApp extends ConsumerWidget {
  const ResellerStudioApp({super.key});

  /// iPhone 14 / 15 logical size — the device the layouts were drawn for.
  /// The locales a build offers, and it is deliberately **not**
  /// [AppLocalizations.supportedLocales].
  ///
  /// `app_vi.arb` holds a few hundred of the app's keys and the generator
  /// fills the rest from English, so a device set to Vietnamese would render
  /// a mixed-language app out of translations hard rule 7 calls unreviewed.
  /// Offering only English is what the Settings row already claims, and the
  /// launch markets are the United States and the United Kingdom.
  ///
  /// The vi keys stay in the ARB (hard rule 7). This list grows again in the
  /// one translation pass at release.
  static const List<Locale> shippingLocales = <Locale>[Locale('en')];

  static const Size designSize = Size(390, 844);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    // Watched, not read: a controller nothing watches is one Riverpod never
    // builds, and this device would never register for pushes. It rebuilds
    // itself on sign-in and sign-out, which is exactly when registration
    // has to change.
    ref.watch(pushControllerProvider);

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
        // Settings owns this now (plan §25). Device-local, so it is read from
        // preferences rather than from the account — see `ThemeModeController`.
        themeMode: ref.watch(themeModeProvider),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: shippingLocales,
        builder: (BuildContext context, Widget? child) =>
            AnnotatedRegion<SystemUiOverlayStyle>(
              // Covers the routes with no app bar — splash, login, a
              // full-screen sheet — which would otherwise keep whatever the
              // platform last set. Same derivation the app bar theme uses, so
              // there is still one place the style is decided, and it unwinds
              // with the route rather than leaking like `SystemChrome` does.
              value: AppTheme.statusBarStyle(Theme.of(context).brightness),
              child: child ?? const SizedBox.shrink(),
            ),
      ),
    );
  }
}
