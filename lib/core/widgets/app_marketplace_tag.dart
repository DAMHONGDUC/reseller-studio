import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/marketplaces/providers.dart';
import '../theme/app_tag_hue.dart';

/// A marketplace's name, wearing the colour the seller gave it.
///
/// **The only two presenters for a marketplace**, alongside
/// [AppMarketplaceDot] — orders, home, payouts and analytics all name one, and
/// none of them may map an id to a colour itself
/// (`lib/features/marketplaces/AGENTS.md`). In `core/widgets/` because more
/// than one feature uses it.
///
/// **The name is always drawn.** The hue is a second way to find a row, never
/// the only one, and two marketplaces may share a colour.
///
/// An id with no record falls back to grey through `AppTagHue.fromName`, so a
/// past order naming a hard-deleted marketplace still renders.
class AppMarketplaceTag extends ConsumerWidget {
  const AppMarketplaceTag({
    required this.marketplaceId,
    required this.name,
    this.size = SdBadgeSizeV3.regular,
    super.key,
  });

  final String marketplaceId;

  /// What the seller calls it. Handed in rather than looked up: an order
  /// carries the name it was sold under, which is the name that must show.
  final String name;

  final SdBadgeSizeV3 size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdBadgeV3(
    label: name,
    color: AppMarketplaceDot.hueOf(ref, marketplaceId).of(context),
    size: size,
  );
}

/// A marketplace's colour as a dot, for a line that already reads its name.
///
/// Where a badge would be too heavy — a card's supporting line, a section
/// heading — the dot sits in front of the words instead. It carries no
/// semantics of its own: the name beside it is what a screen reader reads.
class AppMarketplaceDot extends ConsumerWidget {
  const AppMarketplaceDot({required this.marketplaceId, super.key});

  final String marketplaceId;

  /// Small enough to read as punctuation beside a line of text rather than as
  /// a control asking to be tapped.
  static const double diameter = 8;

  /// The hue for a stored id. The one lookup — see the class comment on
  /// [AppMarketplaceTag].
  static AppTagHue hueOf(WidgetRef ref, String marketplaceId) =>
      ref.watch(marketplaceHuesProvider)[marketplaceId] ?? AppTagHue.grey;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExcludeSemantics(
    child: Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: hueOf(ref, marketplaceId).of(context),
        shape: BoxShape.circle,
      ),
    ),
  );
}
