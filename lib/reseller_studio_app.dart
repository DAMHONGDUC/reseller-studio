import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_design/index.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/app_startup_failure.dart';
import 'core/config/app_env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_screen_util.dart';
import 'core/widgets/splash_screen.dart';
import 'core/widgets/startup_error_screen.dart';
import 'features/app_config/presentation/widgets/force_update_gate.dart';
import 'features/app_config/providers.dart';
import 'features/notifications/providers.dart';
import 'features/settings/presentation/controllers/theme_mode_controller.dart';
import 'l10n/gen/app_localizations.dart';

/// The app widget.
///
/// **[AppScreenUtil] sits above `MaterialApp` and is not optional.** Every
/// dimension in the design system resolves through `SdSpacingConstant`, whose
/// getters call screenutil at *runtime* — so without it in the tree, the
/// first `SdSpacingConstant.w16` a widget reads throws. It also carries the
/// clamp that stops a tablet scaling every token; that widget's own doc has
/// the rest.
class ResellerStudioApp extends ConsumerWidget {
  const ResellerStudioApp({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStartupFailure? failure = AppBootstrap.startupFailure;

    // Read before anything is watched. The router's own providers reach for
    // the SDK that just failed, so building it would trade one screen the
    // seller can read for an exception they cannot.
    if (failure != null) return _StartupErrorApp(failure: failure);

    final GoRouter router = ref.watch(routerProvider);
    final PackageInfo? packageInfo = ref.watch(packageInfoProvider).value;

    // Watched, not read: a controller nothing watches is one Riverpod never
    // builds, and this device would never register for pushes. It rebuilds
    // itself on sign-in and sign-out, which is exactly when registration
    // has to change.
    ref.watch(pushControllerProvider);

    return AppScreenUtil(
      builder: (BuildContext context) => SdDevWrapper(
        envName: AppEnv.flavor.name,
        buildName: packageInfo?.version ?? '',
        buildNumber: packageInfo?.buildNumber ?? '',
        // The flavour, never `kDebugMode`: a TestFlight build of the dev
        // flavour is a release binary and is the one nobody can otherwise
        // tell apart from the real app in a screenshot.
        visible: !AppEnv.flavor.isProd,
        child: MaterialApp.router(
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
                // The splash is outermost: it runs the fresh-install wipe,
                // and that must finish before `ForceUpdateGate` reads
                // `app_config` — that read starts the Firestore client the
                // wipe has to terminate.
                child: SplashScreen(
                  // Above every route rather than on one: a build too old to
                  // run is about the binary, so the sheet is raised over
                  // whatever the seller was looking at.
                  child: ForceUpdateGate(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// The whole app when it could not start: the same theme and the same strings,
/// with [StartupErrorScreen] where the router would be.
///
/// **A separate `MaterialApp`, not a route.** The router is the thing that
/// cannot be built here, and the theme and the locales still have to be, so
/// this is the shortest path from `runApp` to a sentence the seller can read.
/// `themeMode` is deliberately not read: preferences are themselves a startup
/// step, so this screen follows the device rather than a value that may never
/// have loaded.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.failure});

  final AppStartupFailure failure;

  @override
  Widget build(BuildContext context) => AppScreenUtil(
    builder: (BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: ResellerStudioApp.shippingLocales,
      home: StartupErrorScreen(failure: failure),
    ),
  );
}
