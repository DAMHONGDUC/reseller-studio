import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

/// Analytics — "how is my business performing?".
///
/// Sections are Sales, Profit, Inventory, Marketplace, Categories and Sources
/// (plan §9). Every figure must trace back to real transaction data, and a
/// number this screen cannot derive renders as an em dash, never as zero —
/// see [SdStatTileV3.emptyPlaceholder] and plan §15.
///
/// Scaffolded: the frame is real (v3 scaffold, app bar, empty state) and the
/// data is not wired yet.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SdScaffoldV3(
    appBar: SdAppBarV3(title: 'Analytics'),
    body: SdEmptyStateV3(
      icon: Symbols.bar_chart_rounded,
      title: 'Not enough data yet',
      message: 'This screen is scaffolded. Data is not wired up yet.',
    ),
  );
}
