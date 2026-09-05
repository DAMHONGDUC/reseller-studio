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
/// are.** Free holds unlimited items and orders, so a screen asking for either
/// gets nothing today; putting a ceiling back on the table makes its meter
/// appear with nothing in this file changing. That is the whole reason it
/// reads the table rather than naming three figures — a meter that names a
/// number is a meter that outlives it.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlanLimits limits = ref.watch(currentLimitsProvider);
    final List<PlanAllowance> asked = allowances ?? PlanAllowance.values;
    final List<PlanAllowance> capped = asked
        .where((PlanAllowance allowance) => allowance.ceilingIn(limits) != null)
        .toList(growable: false);

    if (capped.isEmpty) return const SizedBox.shrink();

    return Padding(
      // The gaps belong inside, so nothing is left behind when the card is
      // not drawn at all.
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.sectionGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.listItemGap,
      ),
      child: SdCardV3(
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
