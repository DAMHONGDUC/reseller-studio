import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/router/app_routes.dart';

/// More — "where do I manage everything else?".
///
/// Everything the plan deliberately kept off the bottom bar: Sourcing,
/// Listings, Expenses, Reports, Receipts, Categories, Locations,
/// Marketplaces, Team, Settings (plan §10).
///
/// **This screen growing is fine. The bottom bar growing is not** — five tabs
/// is a product decision (hard rule 13), and this list is where the pressure
/// to add a sixth goes instead.
///
/// Destinations with no screen yet are rendered as disabled rows rather than
/// hidden. Hiding them would make the app look finished; showing them greyed
/// says what is coming and stops a tap leading nowhere.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const List<_MoreDestination> _destinations = <_MoreDestination>[
    _MoreDestination(
      label: 'Sourcing',
      icon: Symbols.storefront_rounded,
      route: AppRoutes.sourcing,
    ),
    _MoreDestination(
      label: 'Listings',
      icon: Symbols.sell_rounded,
      route: AppRoutes.listings,
    ),
    _MoreDestination(
      label: 'Expenses',
      icon: Symbols.receipt_rounded,
      route: AppRoutes.expenses,
    ),
    _MoreDestination(
      label: 'Reports',
      icon: Symbols.summarize_rounded,
      route: AppRoutes.reports,
    ),
    _MoreDestination(
      label: 'Receipts',
      icon: Symbols.description_rounded,
      route: AppRoutes.receipts,
    ),
    _MoreDestination(
      label: 'Categories',
      icon: Symbols.category_rounded,
      route: AppRoutes.categories,
    ),
    _MoreDestination(
      label: 'Locations',
      icon: Symbols.shelves,
      route: AppRoutes.locations,
    ),
    _MoreDestination(
      label: 'Marketplaces',
      icon: Symbols.hub_rounded,
      route: AppRoutes.marketplaces,
    ),
    _MoreDestination(
      label: 'Team',
      icon: Symbols.group_rounded,
      route: AppRoutes.team,
    ),
    _MoreDestination(
      label: 'Settings',
      icon: Symbols.settings_rounded,
      route: AppRoutes.settings,
      isBuilt: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdScaffoldV3(
    appBar: const SdAppBarV3(title: 'More'),
    body: ListView(
      padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
      children: <Widget>[
        const SdSectionHeaderV3(title: 'Manage', first: true),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: SdCardV3(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (final _MoreDestination destination in _destinations)
                  _MoreRow(
                    destination: destination,
                    isLast: destination == _destinations.last,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MoreDestination {
  const _MoreDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.isBuilt = false,
  });

  final String label;
  final IconData icon;
  final String route;

  /// False until the destination has a screen. Drives the disabled look and
  /// the "Soon" badge — see the class doc for why these are shown at all.
  final bool isBuilt;
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.destination, required this.isLast});

  final _MoreDestination destination;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destination.isBuilt
        ? context.sdTheme3.textPrimary
        : context.sdTheme3.textTertiary;

    return Column(
      children: <Widget>[
        InkWell(
          onTap: destination.isBuilt
              ? () => context.push(destination.route)
              : null,
          child: Padding(
            padding: SdContentPaddingV3.row,
            child: Row(
              children: <Widget>[
                SdIconV3(destination.icon, color: foreground),
                SizedBox(width: SdSpacingConstant.w12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: context.textTheme3.bodyLarge!.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (!destination.isBuilt)
                  const SdBadgeV3(label: 'Soon')
                else
                  SdIconV3(
                    Symbols.chevron_right_rounded,
                    size: SdIconV3.smallSize,
                    color: context.sdTheme3.textTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: context.sdTheme3.divider),
      ],
    );
  }
}
