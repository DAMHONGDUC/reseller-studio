import 'package:flutter/widgets.dart';

import '../../core/constants/app_icon_constant.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';

/// One row on the More screen.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the row carries a [kind] and [MoreLabel] turns it into words — which is
/// also what keeps this list `const`.
class MoreDestination {
  const MoreDestination({
    required this.kind,
    required this.icon,
    required this.route,
    this.isBuilt = false,
  });

  final MoreDestinationKind kind;
  final IconData icon;
  final String route;

  /// False until the destination has a screen. Drives the disabled look and
  /// the "Soon" badge.
  final bool isBuilt;
}

/// What a More row points at.
enum MoreDestinationKind {
  sourcing,
  listings,
  expenses,
  payouts,
  reports,
  receipts,
  categories,
  locations,
  marketplaces,
  carriers,
  team,
  activity,
  tax,
  subscription,
  settings,
}

/// The words for a More row.
final class MoreLabel {
  static String of(BuildContext context, MoreDestinationKind kind) =>
      switch (kind) {
        MoreDestinationKind.sourcing => context.l10n.moreSourcing,
        MoreDestinationKind.listings => context.l10n.moreListings,
        MoreDestinationKind.expenses => context.l10n.moreExpenses,
        MoreDestinationKind.payouts => context.l10n.payoutsTitle,
        MoreDestinationKind.reports => context.l10n.moreReports,
        MoreDestinationKind.receipts => context.l10n.moreReceipts,
        MoreDestinationKind.categories => context.l10n.moreCategories,
        MoreDestinationKind.locations => context.l10n.moreLocations,
        MoreDestinationKind.marketplaces => context.l10n.moreMarketplaces,
        MoreDestinationKind.carriers => context.l10n.carriersTitle,
        MoreDestinationKind.team => context.l10n.moreTeam,
        MoreDestinationKind.activity => context.l10n.moreActivity,
        MoreDestinationKind.tax => context.l10n.moreTax,
        MoreDestinationKind.subscription => context.l10n.moreSubscription,
        MoreDestinationKind.settings => context.l10n.moreSettings,
      };
}

/// One titled group on More.
class MoreSection {
  const MoreSection({required this.kind, required this.destinations});

  final MoreSectionKind kind;
  final List<MoreDestination> destinations;
}

/// The four questions that split More's destinations into readable groups.
enum MoreSectionKind { operations, finance, business, account }

/// The localized title for a More section.
final class MoreSectionLabel {
  static String of(BuildContext context, MoreSectionKind kind) =>
      switch (kind) {
        MoreSectionKind.operations => context.l10n.moreSectionOperations,
        MoreSectionKind.finance => context.l10n.moreSectionFinance,
        MoreSectionKind.business => context.l10n.moreSectionBusiness,
        MoreSectionKind.account => context.l10n.moreSectionAccount,
      };
}

/// What the More screen lists, kept off the widget that renders it.
///
/// **This list growing is fine. The bottom bar growing is not** — five tabs is
/// a product decision (hard rule 13), and this list is where the pressure to
/// add a sixth goes instead.
///
/// Destinations with no screen yet stay in the list and render disabled rather
/// than being hidden. Hiding them would make the app look finished; showing
/// them greyed says what is coming and stops a tap leading nowhere.
final class MoreConstant {
  static const List<MoreSection> sections = <MoreSection>[
    MoreSection(
      kind: MoreSectionKind.operations,
      destinations: <MoreDestination>[
        MoreDestination(
          kind: MoreDestinationKind.sourcing,
          icon: AppIconConstant.storefront,
          route: AppRoutes.sourcing,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.listings,
          icon: AppIconConstant.sell,
          route: AppRoutes.listings,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.categories,
          icon: AppIconConstant.category,
          route: AppRoutes.categories,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.locations,
          icon: AppIconConstant.shelves,
          route: AppRoutes.locations,
          isBuilt: true,
        ),
      ],
    ),
    MoreSection(
      kind: MoreSectionKind.business,
      destinations: <MoreDestination>[
        MoreDestination(
          kind: MoreDestinationKind.marketplaces,
          icon: AppIconConstant.hub,
          route: AppRoutes.marketplaces,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.carriers,
          icon: AppIconConstant.localShipping,
          route: AppRoutes.carriers,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.team,
          icon: AppIconConstant.group,
          route: AppRoutes.team,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.activity,
          icon: AppIconConstant.history,
          route: AppRoutes.activity,
          isBuilt: true,
        ),
      ],
    ),
    MoreSection(
      kind: MoreSectionKind.finance,
      destinations: <MoreDestination>[
        MoreDestination(
          kind: MoreDestinationKind.expenses,
          icon: AppIconConstant.receipt,
          route: AppRoutes.expenses,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.payouts,
          icon: AppIconConstant.accountBalance,
          route: AppRoutes.payouts,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.reports,
          icon: AppIconConstant.summarize,
          route: AppRoutes.reports,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.receipts,
          icon: AppIconConstant.description,
          route: AppRoutes.receipts,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.tax,
          icon: AppIconConstant.accountBalance,
          route: AppRoutes.tax,
          isBuilt: true,
        ),
      ],
    ),

    MoreSection(
      kind: MoreSectionKind.account,
      destinations: <MoreDestination>[
        MoreDestination(
          kind: MoreDestinationKind.subscription,
          icon: AppIconConstant.workspacePremium,
          route: AppRoutes.subscription,
          isBuilt: true,
        ),
        MoreDestination(
          kind: MoreDestinationKind.settings,
          icon: AppIconConstant.settings,
          route: AppRoutes.settings,
          isBuilt: true,
        ),
      ],
    ),
  ];

  static List<MoreDestination> get destinations => sections
      .expand((MoreSection section) => section.destinations)
      .toList(growable: false);

  static List<MoreSection> sectionsFor({required bool signedIn}) {
    if (signedIn) return sections;

    final MoreDestination settings = destinations.firstWhere(
      (MoreDestination destination) =>
          destination.kind == MoreDestinationKind.settings,
    );

    return <MoreSection>[
      MoreSection(
        kind: MoreSectionKind.account,
        destinations: <MoreDestination>[settings],
      ),
    ];
  }
}
