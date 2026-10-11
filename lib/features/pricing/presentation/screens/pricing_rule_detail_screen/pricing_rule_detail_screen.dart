import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/state/form_seed.dart';
import '../../../../../core/utils/text_input_utils.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../../inventory/domain/entities/item_category.dart';
import '../../../../inventory/providers.dart';
import '../../../../marketplaces/domain/entities/marketplace.dart';
import '../../../../marketplaces/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/pricing_quote.dart';
import '../../../domain/entities/pricing_rule.dart';
import '../../../domain/enums/price_rounding.dart';
import '../../../domain/enums/pricing_rule_scope.dart';
import '../../../domain/services/pricing_rule_calculator.dart';
import '../../../providers.dart';
import '../../controllers/pricing_rule_form_controller.dart';

part 'pricing_rule_detail_screen_choice.dart';
part 'pricing_rule_detail_screen_preview.dart';
part 'pricing_rule_detail_screen_scope.dart';

/// Create or edit one pricing rule, with the price it gives shown as the
/// seller types (`docs/DROPSHIPPING_PLAN.md`).
class PricingRuleDetailScreen extends ConsumerStatefulWidget {
  const PricingRuleDetailScreen({this.ruleId, super.key});

  final String? ruleId;

  @override
  ConsumerState<PricingRuleDetailScreen> createState() =>
      _PricingRuleDetailScreenState();
}

class _PricingRuleDetailScreenState
    extends ConsumerState<PricingRuleDetailScreen>
    with FormSeed<PricingRuleDetailScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _multiplier = TextEditingController(text: '2');
  final TextEditingController _fixedAdd = TextEditingController();
  final TextEditingController _minProfit = TextEditingController();
  final TextEditingController _sampleCost = TextEditingController();
  PricingRuleScope _scope = PricingRuleScope.all;
  String? _scopeId;
  PriceRounding _rounding = PriceRounding.ninetyNine;
  late final String _id = widget.ruleId ?? SdId.unique();
  DateTime _createdAt = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _multiplier.dispose();
    _fixedAdd.dispose();
    _minProfit.dispose();
    _sampleCost.dispose();
    super.dispose();
  }

  void _seed(PricingRule rule) {
    _name.text = rule.name;
    _multiplier.text = TextInputUtils.decimalText(rule.multiplier);
    _fixedAdd.text = rule.fixedAdd?.toInputString() ?? '';
    _minProfit.text = rule.minProfit?.toInputString() ?? '';
    _scope = rule.scope;
    _scopeId = rule.scopeId;
    _rounding = rule.rounding;
    _createdAt = rule.createdAt;
  }

  /// The rule the boxes describe right now, or null while one cannot be read.
  PricingRule? _draft(String currency) {
    final double? multiplier = TextInputUtils.decimalOrNull(_multiplier.text);

    if (multiplier == null || multiplier <= 0) return null;

    return PricingRule(
      id: _id,
      name: _name.text.trim(),
      createdAt: _createdAt,
      scope: _scope,
      scopeId: _scope == PricingRuleScope.all ? null : _scopeId,
      multiplier: multiplier,
      fixedAdd: Money.tryParse(_fixedAdd.text, currency),
      rounding: _rounding,
      minProfit: Money.tryParse(_minProfit.text, currency),
    );
  }

  bool get _scopeComplete => _scope == PricingRuleScope.all || _scopeId != null;

  Future<void> _submit(PricingRule? draft) async {
    final NavigatorState navigator = Navigator.of(context);

    if (draft == null || draft.name.isEmpty || !_scopeComplete) return;

    try {
      final String? id = await ref
          .read(pricingRuleFormControllerProvider.notifier)
          .submit(draft);
      if (id == null || !mounted) return;
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _delete(String ruleId) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref.read(pricingRuleFormControllerProvider.notifier).delete(ruleId);
      if (!mounted) return;
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _confirmDelete(String ruleId) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.pricingRuleDeleteTitle,
      message: context.l10n.pricingRuleDeleteBody,
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.actionDelete,
          isDestructive: true,
          onPressed: () => _delete(ruleId),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool isSaving = ref.watch(pricingRuleFormControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final String? id = widget.ruleId;
    final AsyncValue<List<PricingRule>> source = ref.watch(
      pricingRulesProvider,
    );
    final PricingRule? existing = id == null
        ? null
        : source.value
              ?.where((PricingRule rule) => rule.id == id && !rule.isDeleted)
              .firstOrNull;
    final PricingRule? draft = _draft(currency);
    final bool multiplierInvalid =
        _multiplier.text.trim().isNotEmpty && draft == null;
    final bool canSave =
        !isSaving && draft != null && draft.name.isNotEmpty && _scopeComplete;

    if (id != null && !source.hasValue) return const SdLoadingV3Page();
    if (existing != null) seedOnce(() => _seed(existing));

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: id == null
            ? context.l10n.pricingRuleAdd
            : context.l10n.pricingRuleEditTitle,
        actions: <Widget>[
          if (id != null)
            SdAppBarActionButtonV3(
              icon: AppIconConstant.delete,
              tooltip: context.l10n.actionDelete,
              tint: context.sdTheme3.danger,
              onPressed: isSaving ? null : () => _confirmDelete(id),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                SdTextFieldV3(
                  label: context.l10n.pricingRuleNameLabel,
                  controller: _name,
                  hint: context.l10n.pricingRuleNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (String _) => setState(() {}),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                _ScopeField(
                  scope: _scope,
                  scopeId: _scopeId,
                  onScope: (PricingRuleScope scope) => setState(() {
                    _scope = scope;
                    _scopeId = null;
                  }),
                  onScopeId: (String id) => setState(() => _scopeId = id),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                SdTextFieldV3(
                  label: context.l10n.pricingRuleMultiplierLabel,
                  controller: _multiplier,
                  isRequired: true,
                  errorText: multiplierInvalid
                      ? context.l10n.pricingRuleMultiplierError
                      : null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (String _) => setState(() {}),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                MoneyField(
                  label: context.l10n.pricingRuleFixedAddLabel,
                  controller: _fixedAdd,
                  currency: currency,
                  onChanged: (String _) => setState(() {}),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                _ChoiceField<PriceRounding>(
                  label: context.l10n.pricingRuleRoundingLabel,
                  values: PriceRounding.values,
                  selected: _rounding,
                  labelOf: (PriceRounding value) => value.label(context),
                  colorOf: (PriceRounding value) => value.color(context),
                  onSelected: (PriceRounding value) =>
                      setState(() => _rounding = value),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                MoneyField(
                  label: context.l10n.pricingRuleMinProfitLabel,
                  controller: _minProfit,
                  currency: currency,
                  helperText: context.l10n.pricingRuleMinProfitHelper,
                  onChanged: (String _) => setState(() {}),
                ),
                _Preview(
                  rule: draft,
                  cost: _sampleCost,
                  currency: currency,
                  onChanged: () => setState(() {}),
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: isSaving,
            onPressed: canSave ? () => _submit(draft) : null,
          ),
        ],
      ),
    );
  }
}
