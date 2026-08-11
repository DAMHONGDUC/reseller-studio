import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

/// Inventory — "what do I have?".
///
/// Statuses are fixed by the plan (§7): `All | Listed | Reserved | Sold |
/// Stale`, rendered as a row of [SdFilterChipV3] with counts — which is why
/// that widget carries its count inside rather than beside it.
///
/// Bulk selection belongs here and matters more than it looks: reprice,
/// relist and archive are things a seller does to forty rows at once, and a
/// screen that only edits one item at a time is why people keep using
/// spreadsheets.
///
/// Scaffolded: the frame is real (v3 scaffold, app bar, empty state) and the
/// data is not wired yet. The empty state is what a new workspace genuinely
/// sees, so this screen is honest rather than mocked.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SdScaffoldV3(
    appBar: SdAppBarV3(title: 'Inventory'),
    body: SdEmptyStateV3(
      icon: Symbols.inventory_2_rounded,
      title: 'No items yet',
      message: 'This screen is scaffolded. Data is not wired up yet.',
    ),
  );
}
