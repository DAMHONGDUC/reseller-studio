import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reseller_studio/core/analytics/app_analytics.dart';
import 'package:reseller_studio/core/analytics/app_screen_tracker.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:system_design/common.dart';

/// **A screen view is a route template, and a tab's root is not one of them.**
///
/// The template keeps one screen one series and keeps record ids out of a
/// third-party report; the tab roots belong to `AppShell`, and counting them
/// here as well would report every tab switch twice.
class _RecordingAnalytics implements AppAnalytics {
  final List<String> screens = <String>[];

  @override
  void screenViewed({required String screen}) => screens.add(screen);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) =>
          const SizedBox.shrink(),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (BuildContext context, GoRouterState state) =>
          const SizedBox.shrink(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (BuildContext context, GoRouterState state) =>
          const SizedBox.shrink(),
    ),
  ],
);

void main() {
  late _RecordingAnalytics analytics;
  late GoRouter router;

  setUp(() {
    final AppAnalytics previous = AppAnalytics.instance;

    SdLogger.enabled = false;
    analytics = _RecordingAnalytics();
    AppAnalytics.instance = analytics;
    addTearDown(() => AppAnalytics.instance = previous);
  });

  Future<void> pumpTracked(WidgetTester tester) async {
    final AppScreenTracker tracker;

    router = _router();
    tracker = AppScreenTracker(router)..attach();
    addTearDown(tracker.detach);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('a pushed screen reports its template, not its location', (
    WidgetTester tester,
  ) async {
    await pumpTracked(tester);

    unawaited(router.push('/orders/ord-4'));
    await tester.pumpAndSettle();

    expect(analytics.screens, <String>[AppRoutes.orderDetail]);
  });

  testWidgets('a tab root is left to AppShell', (WidgetTester tester) async {
    await pumpTracked(tester);

    router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(analytics.screens, <String>[AppRoutes.login]);
  });

  testWidgets('coming back to a screen counts it again', (
    WidgetTester tester,
  ) async {
    await pumpTracked(tester);

    unawaited(router.push('/orders/ord-4'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    unawaited(router.push('/orders/ord-5'));
    await tester.pumpAndSettle();

    expect(analytics.screens, <String>[
      AppRoutes.orderDetail,
      AppRoutes.orderDetail,
    ]);
  });
}
