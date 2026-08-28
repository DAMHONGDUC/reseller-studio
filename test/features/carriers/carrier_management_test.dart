import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/carriers/domain/entities/carrier.dart';
import 'package:reseller_studio/features/carriers/domain/repositories/carrier_repository.dart';
import 'package:reseller_studio/features/carriers/presentation/controllers/carrier_form_controller.dart';
import 'package:reseller_studio/features/carriers/presentation/screens/carrier_detail_screen/carrier_detail_screen.dart';
import 'package:reseller_studio/features/carriers/presentation/screens/carriers_screen/carriers_screen.dart';
import 'package:reseller_studio/features/carriers/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart'
    as mock_providers;
import 'package:reseller_studio/features/settings/presentation/screens/settings_screen/settings_screen.dart';

import '../../support/pump_app.dart';

void main() {
  test('a new business receives five editable carrier defaults', () {
    final ProviderContainer container = mockContainer();
    final List<Carrier> defaults = container.read(defaultCarriersProvider);

    expect(defaults.map((Carrier carrier) => carrier.name), <String>[
      'USPS',
      'UPS',
      'FedEx',
      'DHL',
      'Royal Mail',
    ]);
  });

  testWidgets('Settings carrier list opens editable records', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const CarriersScreen());

    expect(find.text('Add carrier'), findsOneWidget);
    expect(find.text('USPS'), findsOneWidget);
    expect(find.text('Royal Mail'), findsOneWidget);

    await pumpScreen(tester, const CarrierDetailScreen(carrierId: 'usps'));

    expect(find.text('Edit carrier'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'USPS'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('Settings exposes carrier management', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SettingsScreen());
    await tester.scrollUntilVisible(find.text('Carriers'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Carriers'), findsOneWidget);
    expect(
      find.text('Manage the carriers offered when shipping an order'),
      findsOneWidget,
    );
  });

  test('carrier controller adds, edits, and soft-deletes records', () async {
    final ProviderContainer container = mockContainer();
    final CarrierFormController controller = container.read(
      carrierFormControllerProvider.notifier,
    );
    final CarrierRepository repository = container.read(
      mock_providers.carrierRepositoryProvider,
    );

    final String? id = await controller.submit(name: 'Evri');
    expect(id, isNotNull);

    await controller.submit(name: 'Evri UK', carrierId: id);
    Carrier changed = (await repository.watchCarriers().first).firstWhere(
      (Carrier carrier) => carrier.id == id,
    );
    expect(changed.name, 'Evri UK');

    await controller.delete(id!);
    changed = (await repository.watchCarriers().first).firstWhere(
      (Carrier carrier) => carrier.id == id,
    );
    expect(changed.isDeleted, isTrue);
  });
}
