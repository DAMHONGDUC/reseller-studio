import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/widgets/app_filter_chip_group.dart';
import '../../../../core/widgets/app_filter_sheet_actions.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_filter_criteria.dart';
import '../../domain/enums/order_deadline_filter.dart';
import '../../domain/enums/order_filter_group.dart';
import '../../domain/enums/order_status.dart';
import '../../providers.dart';
import '../order_filter_label.dart';
import '../order_status_label.dart';

part 'order_filter_sheet_group.dart';

/// Everything Orders can be narrowed by — the whole sheet, or one group of
/// it opened from its chip on the strip.
///
/// The same shape Inventory's has — a draft the chips edit, written to the
/// screen only when Apply is pressed, with the Show preset as its first
/// group. See `InventoryFilterSheet` for the rule and its reason.
class OrderFilterSheet extends ConsumerStatefulWidget {
  const OrderFilterSheet({
    this.preset = true,
    this.groups = OrderFilterGroup.values,
    super.key,
  });

  /// Whether the Show preset is offered.
  final bool preset;

  /// The groups offered after the preset, in the sheet's order.
  final List<OrderFilterGroup> groups;

  /// How much of the screen the whole sheet takes. The same fraction
  /// Inventory's uses: two sheets a seller opens from neighbouring tabs must
  /// not be two heights.
  static const double heightFactor = 0.85;

  /// The tallest a one-group sheet's chips grow before they scroll.
  static const double groupHeightFactor = 0.6;

  /// The whole sheet — the strip's Filters chip.
  static Future<void> show(BuildContext context) =>
      _present(context, const OrderFilterSheet());

  /// The Show preset alone.
  static Future<void> showPreset(BuildContext context) =>
      _present(context, const OrderFilterSheet(groups: <OrderFilterGroup>[]));

  /// One group alone — its chip on the strip.
  static Future<void> showGroup(BuildContext context, OrderFilterGroup group) =>
      _present(
        context,
        OrderFilterSheet(preset: false, groups: <OrderFilterGroup>[group]),
      );

  static Future<void> _present(BuildContext context, OrderFilterSheet sheet) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => sheet,
      );

  /// Whether this is the whole sheet rather than one group of it.
  bool get isWhole => preset && groups.length == OrderFilterGroup.values.length;

  @override
  ConsumerState<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends ConsumerState<OrderFilterSheet> {
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();

  /// What the seller has ticked so far — see `InventoryFilterSheet`. The two
  /// boxes above are the same draft, held as text because that is what a
  /// field edits.
  late OrderFilterCriteria _draft = ref.read(orderCriteriaProvider);

  /// The Show preset, pending like everything else here.
  late OrderFilter _tab = ref.read(orderFilterProvider);

  @override
  void initState() {
    super.initState();

    // Seeded once, from the same read the draft starts at.
    _min.text = _draft.minSale?.toInputString() ?? '';
    _max.text = _draft.maxSale?.toInputString() ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _edit(OrderFilterCriteria next) => setState(() => _draft = next);

  void _selectTab(OrderFilter tab) => setState(() => _tab = tab);

  void _apply() {
    ref.read(orderCriteriaProvider.notifier).apply(_draft, tab: _tab);
    Navigator.of(context).pop();
  }

  /// Empties what this sheet shows, and leaves every other group alone.
  void _reset() {
    if (widget.groups.contains(OrderFilterGroup.saleRange)) {
      _min.clear();
      _max.clear();
    }
    setState(() {
      if (widget.preset) _tab = OrderFilter.all;
      _draft = widget.groups.fold(
        _draft,
        (OrderFilterCriteria criteria, OrderFilterGroup group) =>
            criteria.cleared(group),
      );
    });
  }

  String _title(BuildContext context) {
    if (widget.isWhole) return context.l10n.filterTitle;
    if (widget.groups.isEmpty) return context.l10n.filterShow;

    return widget.groups.single.label(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWhole = widget.isWhole;
    final int pending =
        (widget.preset && _tab != OrderFilter.all ? 1 : 0) +
        widget.groups.where(_draft.narrows).length;
    final List<Widget> sections = <Widget>[
      if (widget.preset)
        _PresetGroup(
          draft: _draft,
          selected: _tab,
          showTitle: isWhole,
          onSelected: _selectTab,
        ),
      for (final OrderFilterGroup group in widget.groups)
        _OrderFilterGroupView(
          group: group,
          draft: _draft,
          showTitle: isWhole,
          min: _min,
          max: _max,
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
      heightFactor: isWhole ? OrderFilterSheet.heightFactor : null,
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
                    OrderFilterSheet.groupHeightFactor,
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
