import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

/// More — "where do I manage everything else?".
///
/// Everything the plan deliberately kept off the bottom bar: Sourcing,
/// Listings, Expenses, Reports, Receipts, Categories, Locations,
/// Marketplaces, Team, Settings (plan §10).
///
/// This screen growing is fine. The bottom bar growing is not — five tabs is
/// a product decision, not a layout one.
///
/// Scaffolded: the frame is real (v3 scaffold, app bar, empty state) and the
/// destinations are not wired yet.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SdScaffoldV3(
    appBar: SdAppBarV3(title: 'More'),
    body: SdEmptyStateV3(
      icon: Symbols.menu_rounded,
      title: 'Coming together',
      message: 'This screen is scaffolded. Destinations are not wired up yet.',
    ),
  );
}
