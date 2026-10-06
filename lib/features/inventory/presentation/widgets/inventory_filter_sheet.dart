import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/widgets/app_filter_chip_group.dart';
import '../../../../core/widgets/app_filter_sheet_actions.dart';
import '../../../sourcing/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_filter_criteria.dart';
import '../../domain/enums/item_filter_group.dart';
import '../../domain/enums/item_status.dart';
import '../../item_filter_constant.dart';
import '../../providers.dart';

part 'inventory_filter_sheet_group.dart';

/// Everything Inventory can be narrowed by — the whole sheet, or one group
/// of it opened from its chip on the strip.
///
/// **Nothing is applied until Apply is pressed** — owner's rule, and it
/// **reverses "it applies as it is tapped"**. The chips edit a draft this
/// sheet holds; the list behind it does not move while the seller is still
/// deciding, and closing the sheet any other way leaves the list exactly as
/// they found it.
///
/// - **Reset empties what this sheet shows** — every group in the whole
///   sheet, one group in a one-group sheet (`docs/rules/SCREENS.md`)
/// - **The Show preset is the first group**, and part of the draft
class InventoryFilterSheet extends ConsumerStatefulWidget {
  const InventoryFilterSheet({
    this.preset = true,
    this.groups = ItemFilterGroup.values,
    super.key,
  });

  /// Whether the Show preset is offered.
  final bool preset;

  /// The groups offered after the preset, in the sheet's order.
  final List<ItemFilterGroup> groups;

  /// How much of the screen the whole sheet takes. Fixed rather than sized to
  /// its groups: the content grows with the seller's own categories and
  /// locations, so a sheet that fitted it would be a different height in
  /// every business.
  static const double heightFactor = 0.85;

  /// The tallest a one-group sheet's chips grow before they scroll.
  static const double groupHeightFactor = 0.6;

  /// The whole sheet — the strip's Filters chip.
  static Future<void> show(BuildContext context) =>
      _present(context, const InventoryFilterSheet());

  /// The Show preset alone.
  static Future<void> showPreset(BuildContext context) => _present(
    context,
    const InventoryFilterSheet(groups: <ItemFilterGroup>[]),
  );

  /// One group alone — its chip on the strip.
  static Future<void> showGroup(BuildContext context, ItemFilterGroup group) =>
      _present(
        context,
        InventoryFilterSheet(preset: false, groups: <ItemFilterGroup>[group]),
      );

  static Future<void> _present(
    BuildContext context,
    InventoryFilterSheet sheet,
  ) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => sheet,
  );

  /// Whether this is the whole sheet rather than one group of it.
  bool get isWhole => preset && groups.length == ItemFilterGroup.values.length;

  @override
  ConsumerState<InventoryFilterSheet> createState() =>
      _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends ConsumerState<InventoryFilterSheet> {
  /// What the seller has ticked so far. Seeded from what is applied, once:
  /// the sheet opens on the filters the list is already under, and every tap
  /// after that moves this and nothing else.
  late ItemFilterCriteria _draft = ref.read(inventoryCriteriaProvider);

  /// The Show preset, pending like everything else here.
  late InventoryFilter _tab = ref.read(inventoryFilterProvider);

  void _edit(ItemFilterCriteria next) => setState(() => _draft = next);

  void _selectTab(InventoryFilter tab) => setState(() => _tab = tab);

  void _apply() {
    ref.read(inventoryCriteriaProvider.notifier).apply(_draft, tab: _tab);
    Navigator.of(context).pop();
  }

  /// Empties what this sheet shows, and leaves every other group alone.
  void _reset() => setState(() {
    if (widget.preset) _tab = InventoryFilter.all;
    _draft = widget.groups.fold(
      _draft,
      (ItemFilterCriteria criteria, ItemFilterGroup group) =>
          criteria.cleared(group),
    );
  });

  String _title(BuildContext context) {
    if (widget.isWhole) return context.l10n.filterTitle;
    if (widget.groups.isEmpty) return context.l10n.filterShow;

    return widget.groups.single.label(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWhole = widget.isWhole;
    final int pending =
        (widget.preset && _tab != InventoryFilter.all ? 1 : 0) +
        widget.groups.where(_draft.narrows).length;
    final List<Widget> sections = <Widget>[
      if (widget.preset)
        _PresetGroup(
          draft: _draft,
          selected: _tab,
          showTitle: isWhole,
          onSelected: _selectTab,
        ),
      for (final ItemFilterGroup group in widget.groups)
        _ItemFilterGroupView(
          group: group,
          draft: _draft,
          showTitle: isWhole,
          onEdit: _edit,
        ),
    ];
    final Widget body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...<Widget>[
            if (i != 0) const AppFilterGroupDivider(),
            sections[i],
          ],
        ],
      ),
    );

    return SdBottomSheetV3(
      title: _title(context),
      closeTooltip: context.l10n.commonClose,
      // A one-group sheet fits its chips; the whole sheet is a fixed height.
      heightFactor: isWhole ? InventoryFilterSheet.heightFactor : null,
      child: Column(
        mainAxisSize: isWhole ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isWhole)
            Expanded(child: body)
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height *
                    InventoryFilterSheet.groupHeightFactor,
              ),
              child: body,
            ),
          SizedBox(height: SdContentPaddingV3.pinnedActionsGap),
          AppFilterSheetActions(
            pending: pending,
            onReset: _reset,
            onApply: _apply,
          ),
        ],
      ),
    );
  }
}
