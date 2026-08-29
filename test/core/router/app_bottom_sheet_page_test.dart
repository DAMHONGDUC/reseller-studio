import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/router/app_bottom_sheet_page.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

void main() {
  testWidgets('the paywall page creates a modal bottom-sheet route', (
    WidgetTester tester,
  ) async {
    late BuildContext routeContext;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: ResellerStudioApp.designSize,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) {
              routeContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    const AppBottomSheetPage<void> page = AppBottomSheetPage<void>(
      builder: _RouteFixture.new,
    );

    expect(page.createRoute(routeContext), isA<ModalBottomSheetRoute<void>>());
  });
}

class _RouteFixture extends StatelessWidget {
  const _RouteFixture(BuildContext context);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
