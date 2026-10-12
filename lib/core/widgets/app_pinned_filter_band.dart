import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'app_active_filter_bar.dart';
import 'app_filter_strip.dart';

/// Pins a list's filter strip under its docked search header.
///
/// **Owner's rule: a list's chips stay put while it scrolls.** A list whose
/// scrollable holds `SdSearchHeaderV3` — Inventory and Orders — cannot keep
/// the strip in a `Column` above it, because the header has to live inside
/// the scroll to dock; so the strip pins here instead.
///
/// **Still not part of the app bar** (`docs/rules/DESIGN_SYSTEM.md`): its own
/// sliver with the body's background, below the chrome rather than inside it.
/// It carries `topGap` above and below, so the screen places neither, and its
/// extent moves with the count-and-reset row because a pinned sliver states
/// its extent before it lays anything out.
class AppPinnedFilterBand extends SliverPersistentHeaderDelegate {
  const AppPinnedFilterBand({
    required this.strip,
    required this.activeFilters,
    required this.showActiveFilters,
  });

  /// The chips — an `AppFilterStrip`.
  final Widget strip;

  /// The count-and-reset row — an `AppActiveFilterBar`.
  final Widget activeFilters;

  /// Whether the band carries [activeFilters]; only while something is
  /// filtered.
  final bool showActiveFilters;

  /// The gap between the chips and the row under them — inside the band, so
  /// not `topGap`.
  static double get _rowGap => SdSpacingConstant.h8;

  double get _extent =>
      SdContentPaddingV3.topGap * 2 +
      AppFilterStrip.height +
      (showActiveFilters ? _rowGap + AppActiveFilterBar.height : 0);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    // Opaque, or the list scrolls visibly through the pinned band.
    color: context.sdTheme3.background,
    child: Column(
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        strip,
        if (showActiveFilters) ...<Widget>[
          SizedBox(height: _rowGap),
          activeFilters,
        ],
        SizedBox(height: SdContentPaddingV3.topGap),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant AppPinnedFilterBand oldDelegate) =>
      oldDelegate.showActiveFilters != showActiveFilters;
}
