import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/subscription/domain/entities/plan_limits.dart';
import '../../features/subscription/domain/enums/plan_allowance.dart';
import '../../features/subscription/domain/enums/seller_plan.dart';
import '../../features/subscription/providers.dart';

/// What the current plan still has room for — one meter per ceiling.
///
/// **Only a capped allowance is drawn, and `PlanLimits` decides which those
/// are.** Lifting a ceiling there removes its meter and putting one back
/// restores it, with nothing in this file changing. That is the whole reason
/// it reads the table rather than naming three figures — a meter that names a
/// number is a meter that outlives it.
///
/// **No card around it** — owner's rule. A meter is a readout the screen
/// wears, not a record sitting on the page; a card gave it the weight of a row
/// the seller could open.
///
/// A plan with no ceiling at all renders nothing, so Premium needs no check,
/// and neither does a screen placing this.
///
/// In `core/widgets/` because four features draw it: More, Inventory, Orders
/// and the Businesses screen.
class PlanLimitMeters extends ConsumerWidget {
  const PlanLimitMeters({this.allowances, super.key});

  /// Which ceilings this screen is about. **Null means every capped one** —
  /// what More shows, because More is the overview. A list screen names the
  /// one allowance it holds: a meter for businesses on the Inventory screen
  /// answers a question nobody standing there is asking.
  final List<PlanAllowance>? allowances;

  /// Which of [allowances] this would actually draw.
  ///
  /// **Public because a list has to know whether it is getting a header
  /// row.** `_OrderList` builds its meter as item zero, and an index shifted
  /// by a widget that turned out to render nothing is an off-by-one nobody
  /// sees until a plan changes. One predicate, read from both places.
  static List<PlanAllowance> cappedIn(
    WidgetRef ref, {
    List<PlanAllowance>? allowances,
  }) {
    final PlanLimits limits = ref.watch(currentLimitsProvider);

    return (allowances ?? PlanAllowance.values)
        .where((PlanAllowance allowance) => allowance.ceilingIn(limits) != null)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlanLimits limits = ref.watch(currentLimitsProvider);
    final List<PlanAllowance> capped = cappedIn(ref, allowances: allowances);

    if (capped.isEmpty) return const SizedBox.shrink();

    return Padding(
      // The gaps belong inside, so nothing is left behind when nothing is
      // drawn at all.
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.sectionGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.listItemGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 0; index < capped.length; index++) ...<Widget>[
            if (index > 0) SizedBox(height: SdContentPaddingV3.listItemGap),
            _PlanLimitMeter(
              allowance: capped[index],
              limit: capped[index].ceilingIn(limits)!,
            ),
          ],
        ],
      ),
    );
  }
}

/// One allowance's meter. Its own widget so a count changing rebuilds a row
/// rather than the card.
class _PlanLimitMeter extends ConsumerWidget {
  const _PlanLimitMeter({required this.allowance, required this.limit});

  final PlanAllowance allowance;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int used = ref.watch(countedAllowanceProvider(allowance));
    final SellerPlan plan = ref.watch(currentPlanProvider);

    return SdFreeLimitProgressV3(
      title: allowance.meterTitle(plan),
      countLabel: allowance.countLabel(used: used, limit: limit),
      used: used,
      limit: limit,
    );
  }
}
