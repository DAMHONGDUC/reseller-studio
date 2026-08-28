import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/more/more_constant.dart';

void main() {
  test('Carriers is a direct business destination on More', () {
    final MoreSection business = MoreConstant.sections.firstWhere(
      (MoreSection section) => section.kind == MoreSectionKind.business,
    );
    final MoreDestination carrier = business.destinations.firstWhere(
      (MoreDestination destination) =>
          destination.kind == MoreDestinationKind.carriers,
    );

    expect(carrier.route, AppRoutes.carriers);
    expect(carrier.isBuilt, isTrue);
  });
}
