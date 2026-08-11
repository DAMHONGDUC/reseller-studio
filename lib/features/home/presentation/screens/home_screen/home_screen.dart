import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';

/// Home — "what do I need to do today?".
///
/// The plan's core UX principle lands here and nowhere else: *the app tells
/// the seller what needs attention today, then makes the action fast*. The
/// section order below is that sentence, and it is not arbitrary —
/// **Needs Attention comes before Today's Overview** even though the plan
/// (§6) lists the overview first. A seller opening the app at 8am needs the
/// four orders waiting to ship, not last night's revenue; the numbers are
/// what they check second.
///
/// Scaffolded: the sections are laid out and the data is not wired. Each
/// `null` value below renders `SdStatTileV3.emptyPlaceholder`, which is the
/// same thing a real workspace with no sales shows — so this screen is
/// honest rather than mocked.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdScaffoldV3(
    appBar: SdAppBarV3(
      title: context.l10n.appTitle,
      actions: <Widget>[
        IconButton(
          onPressed: () {},
          icon: const Icon(Symbols.notifications_rounded),
        ),
        SizedBox(width: SdSpacingConstant.w8),
      ],
    ),
    body: ListView(
      padding: SdContentPaddingV3.fullBleed(context),
      children: <Widget>[
        const SdSectionHeaderV3(title: 'Needs Attention', first: true),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: SdCardV3(
            child: Text(
              'Nothing needs your attention right now.',
              style: context.textTheme3.bodyMedium!.muted3(context),
            ),
          ),
        ),
        const SdSectionHeaderV3(title: "Today's Overview"),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV3.horizontal,
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            mainAxisSpacing: SdContentPaddingV3.listItemGap,
            crossAxisSpacing: SdContentPaddingV3.listItemGap,
            children: const <Widget>[
              SdStatTileV3(
                label: 'Revenue',
                value: null,
                icon: Symbols.payments_rounded,
              ),
              SdStatTileV3(
                label: 'Profit',
                value: null,
                tone: SdStatToneV3.profit,
                icon: Symbols.trending_up_rounded,
              ),
              SdStatTileV3(
                label: 'Orders',
                value: null,
                icon: Symbols.receipt_long_rounded,
              ),
              SdStatTileV3(
                label: 'Inventory',
                value: null,
                icon: Symbols.inventory_2_rounded,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
