import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

/// Orders — "what am I selling and processing?".
///
/// Tabs are `All | To Ship | Shipped | Delivered | Returns` (plan §8), and
/// **Offers live under this tab rather than as a sixth bottom tab** — an
/// offer is the step before an order, not a separate part of the business.
///
/// The shipping queue is where a seller actually spends their time: pick,
/// pack, label, tracking. Optimise that flow before anything else on this
/// screen.
///
/// Scaffolded: the frame is real (v3 scaffold, app bar, empty state) and the
/// data is not wired yet.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SdScaffoldV3(
    appBar: SdAppBarV3(title: 'Orders'),
    body: SdEmptyStateV3(
      icon: Symbols.receipt_long_rounded,
      title: 'No orders yet',
      message: 'This screen is scaffolded. Data is not wired up yet.',
    ),
  );
}
