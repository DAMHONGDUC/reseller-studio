import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../workspace/providers.dart';
import 'carrier_constant.dart';
import 'domain/entities/carrier.dart';

final Provider<List<Carrier>> defaultCarriersProvider = Provider<List<Carrier>>(
  (Ref ref) {
    final DateTime createdAt = DateTime.now();

    return <Carrier>[
      for (final CarrierSeed seed in CarrierConstant.defaults)
        Carrier(id: seed.id, name: seed.name, createdAt: createdAt),
    ];
  },
);

final StreamProvider<List<Carrier>> carriersProvider =
    StreamProvider<List<Carrier>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Carrier>(
        ref,
        () => ref.watch(carrierRepositoryProvider).watchCarriers(),
      );
    });

final Provider<List<Carrier>> activeCarriersProvider = Provider<List<Carrier>>((
  Ref ref,
) {
  return <Carrier>[
    for (final Carrier carrier
        in ref.watch(carriersProvider).value ?? const <Carrier>[])
      if (!carrier.isDeleted) carrier,
  ];
});
