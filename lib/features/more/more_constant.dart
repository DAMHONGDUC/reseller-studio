import 'package:flutter/widgets.dart';

import '../../core/config/app_env.dart';
import '../../core/constants/app_icon_constant.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_tag_hue.dart';
import '../subscription/domain/enums/seller_plan.dart';

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
  businesses,
  books,
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
  notifications,
  about,
  contactSupport,
}

/// The words for a More row.
final class MoreLabel {
  static String of(BuildContext context, MoreDestinationKind kind) =>
      switch (kind) {
        MoreDestinationKind.businesses => context.l10n.workspacesTitle,
        MoreDestinationKind.books => context.l10n.booksTitle,
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
        MoreDestinationKind.notifications =>
          context.l10n.notificationSettingsTitle,
        MoreDestinationKind.about => context.l10n.moreAbout,
        MoreDestinationKind.contactSupport => context.l10n.moreContactSupport,
      };
}

/// The tint of a destination's tile on More.
///
/// **Exhaustive, so a new destination cannot ship untinted**, and by name
/// rather than index (the palette rule in `CLAUDE.md`). Related places share
/// a hue — money is green, stock is indigo — so a section reads as a family.
final class MoreHue {
  static AppTagHue of(MoreDestinationKind kind) => switch (kind) {
    MoreDestinationKind.sourcing => AppTagHue.indigo,
    MoreDestinationKind.listings => AppTagHue.blue,
    MoreDestinationKind.categories => AppTagHue.violet,
    MoreDestinationKind.locations => AppTagHue.teal,
    MoreDestinationKind.businesses => AppTagHue.indigo,
    MoreDestinationKind.marketplaces => AppTagHue.blue,
    MoreDestinationKind.carriers => AppTagHue.amber,
    MoreDestinationKind.team => AppTagHue.green,
    MoreDestinationKind.activity => AppTagHue.grey,
    MoreDestinationKind.expenses => AppTagHue.red,
    MoreDestinationKind.payouts => AppTagHue.green,
    MoreDestinationKind.books => AppTagHue.teal,
    MoreDestinationKind.reports => AppTagHue.violet,
    MoreDestinationKind.receipts => AppTagHue.amber,
    MoreDestinationKind.tax => AppTagHue.grey,
    MoreDestinationKind.subscription => AppTagHue.amber,
    MoreDestinationKind.notifications => AppTagHue.blue,
    MoreDestinationKind.about => AppTagHue.grey,
    MoreDestinationKind.contactSupport => AppTagHue.grey,
  };
}

/// The value at the end of a More row — what the seller would otherwise have
/// to open the screen to find out.
///
/// **One row has one, and the rest return null.** A value on every row would
/// be a second column of text competing with the labels; this one answers a
/// question a seller asks before tapping — which plan am I on. Whether they
/// are signed in, the Account card on More says outright.
final class MoreValueLabel {
  static String? of(
    BuildContext context,
    MoreDestinationKind kind, {
    required SellerPlan plan,
  }) => switch (kind) {
    MoreDestinationKind.subscription => plan.label,
    _ => null,
  };
}

/// One titled group on More.
class MoreSection {
  const MoreSection({required this.kind, required this.destinations});

  final MoreSectionKind kind;
  final List<MoreDestination> destinations;
}

/// The three questions that split More's destinations into readable groups.
enum MoreSectionKind { operations, finance, business }

/// The localized title for a More section.
final class MoreSectionLabel {
  static String of(BuildContext context, MoreSectionKind kind) =>
      switch (kind) {
        MoreSectionKind.operations => context.l10n.moreSectionOperations,
        MoreSectionKind.finance => context.l10n.moreSectionFinance,
        MoreSectionKind.business => context.l10n.moreSectionBusiness,
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
          kind: MoreDestinationKind.businesses,
          icon: AppIconConstant.storefront,
          route: AppRoutes.workspaces,
          isBuilt: true,
        ),
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
          kind: MoreDestinationKind.books,
          icon: AppIconConstant.checkCircle,
          route: AppRoutes.books,
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
  ];

  /// The destinations drawn in the General section, not in [sections] — they
  /// sit among the settings rows (`lib/features/more/CLAUDE.md`).
  static const MoreDestination subscription = MoreDestination(
    kind: MoreDestinationKind.subscription,
    icon: AppIconConstant.workspacePremium,
    route: AppRoutes.subscription,
    isBuilt: true,
  );

  static const MoreDestination notifications = MoreDestination(
    kind: MoreDestinationKind.notifications,
    icon: AppIconConstant.notifications,
    route: AppRoutes.notificationSettings,
    isBuilt: true,
  );

  static const MoreDestination about = MoreDestination(
    kind: MoreDestinationKind.about,
    icon: AppIconConstant.info,
    route: AppRoutes.about,
    isBuilt: true,
  );

  static const MoreDestination contactSupport = MoreDestination(
    kind: MoreDestinationKind.contactSupport,
    icon: AppIconConstant.mail,
    route: AppRoutes.contactSupport,
    isBuilt: true,
  );

  /// General's destinations, in the order General draws them.
  static const List<MoreDestination> general = <MoreDestination>[
    subscription,
    notifications,
    about,
    contactSupport,
  ];

  static List<MoreDestination> get destinations => <MoreDestination>[
    ...sections.expand((MoreSection section) => section.destinations),
    ...general,
  ];

  /// What More lists for this seller.
  ///
  /// **Every row is a `const` destination now.** The business row used to be
  /// built here from the resolved workspace id because it opened one record;
  /// it opens the list instead, which names none
  /// (`lib/features/workspace/CLAUDE.md`).
  /// What a guest cannot be shown, because a server writes it.
  ///
  /// **Four rows, not the whole list** — this used to be the other way round
  /// and left a signed-out seller with Settings alone, which was right when
  /// there was nothing else to show them (`docs/rules/GUEST_MODE.md` reversed
  /// it). Everything else is a view onto records the guest store holds.
  ///
  /// - **Businesses** is switching between accounts' workspaces; a guest has
  ///   exactly one and it is not on a server.
  /// - **Team** addresses an invitation to an email account.
  /// - **Activity** is the audit log, written only by Cloud Functions
  ///   (hard rule 12), so a guest's would be permanently empty — and hard
  ///   rule 5's reasoning says an empty list is a claim.
  /// - **Notifications** reads and writes the signed-in person's own document.
  static const Set<MoreDestinationKind> accountOnly = <MoreDestinationKind>{
    MoreDestinationKind.businesses,
    MoreDestinationKind.team,
    MoreDestinationKind.activity,
    MoreDestinationKind.notifications,
  };

  static List<MoreSection> sectionsFor({required bool signedIn}) =>
      <MoreSection>[
        for (final MoreSection section in sections)
          if (section.destinations.any(
            (MoreDestination destination) => isVisible(destination, signedIn),
          ))
            MoreSection(
              kind: section.kind,
              destinations: section.destinations
                  .where(
                    (MoreDestination destination) =>
                        isVisible(destination, signedIn),
                  )
                  .toList(growable: false),
            ),
      ];

  /// - A guest loses [accountOnly].
  /// - Contact support is not drawn with no address configured.
  static bool isVisible(MoreDestination destination, bool signedIn) =>
      (signedIn || !accountOnly.contains(destination.kind)) &&
      (destination.kind != MoreDestinationKind.contactSupport ||
          AppEnv.hasSupportEmail);
}
