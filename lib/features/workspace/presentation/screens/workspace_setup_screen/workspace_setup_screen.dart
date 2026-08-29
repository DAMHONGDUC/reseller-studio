import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../country_label.dart';
import '../../../country_picker.dart';
import '../../../currency_label.dart';
import '../../../currency_picker.dart';
import '../../../providers.dart';
import '../../../workspace_constant.dart';
import '../../../workspace_option_label.dart';
import '../../controllers/workspace_setup_controller.dart';

/// Workspace setup — the step between signing in and Home (plan §26).
///
/// **Every business record lives under a workspace** (hard rule 14), so this
/// is not a settings screen a seller can skip: without one there is nowhere
/// to write an item. It asks for the three things plan §28 requires and
/// nothing else.
///
/// **The create action is pinned to the bottom** (owner's rule) — only the
/// form scrolls. See `AppPinnedAction`.
class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({this.isAdditional = false, super.key});

  /// True when a seller who already has a business is adding another from the
  /// switcher, rather than a new account being forced through the gate.
  ///
  /// It changes two things and nothing else: the title, and what happens on
  /// success. The first workspace is finished by the router's redirect; an
  /// additional one is a pushed route, so it switches to what it just made
  /// and pops itself.
  final bool isAdditional;

  @override
  ConsumerState<WorkspaceSetupScreen> createState() =>
      _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends ConsumerState<WorkspaceSetupScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final String? code = await CurrencyPicker.show(
      context,
      selected: ref.read(workspaceSetupControllerProvider).currency,
    );

    if (code == null) return;

    ref.read(workspaceSetupControllerProvider.notifier).selectCurrency(code);
  }

  Future<void> _pickCountry() async {
    final String? code = await CountryPicker.show(
      context,
      selected: ref.read(workspaceSetupControllerProvider).country,
    );

    if (code == null) return;

    ref.read(workspaceSetupControllerProvider.notifier).selectCountry(code);
  }

  Future<void> _pickBusinessType() async {
    final String? type = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceBusinessType,
      selected: ref.read(workspaceSetupControllerProvider).businessType,
      options: WorkspaceConstant.businessTypes
          .map(
            (String key) => PickerOption<String>(
              value: key,
              label: WorkspaceOptionLabel.businessType(context, key),
            ),
          )
          .toList(),
    );

    if (type == null) return;

    ref
        .read(workspaceSetupControllerProvider.notifier)
        .selectBusinessType(type);
  }

  /// Creates the workspace. For the first one this stops here — the router
  /// watches `workspaceStatusProvider` and moves the seller to Home itself.
  Future<void> _submit() async {
    final PlanBlock block = ref.read(addWorkspaceBlockProvider);

    if (widget.isAdditional && block != PlanBlock.none) {
      await PlanBlockSheet.show(
        context,
        block: block,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    try {
      final String? id = await ref
          .read(workspaceSetupControllerProvider.notifier)
          .submit();

      if (id == null || !widget.isAdditional) return;

      // Opening what you just created is the only sensible landing: nobody
      // adds a business in order to keep looking at the previous one.
      await ref.read(workspaceSwitchControllerProvider.notifier).switchTo(id);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceSetupState state = ref.watch(
      workspaceSetupControllerProvider,
    );

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: widget.isAdditional
            ? context.l10n.workspaceAddTitle
            : context.l10n.workspaceSetupTitle,
        // The first one is a gate with nothing behind it; an additional one is
        // pushed and must be escapable.
        automaticallyImplyLeading: widget.isAdditional,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              // No bottom inset: the pinned action owns the bottom edge, and
              // its own top gap is what separates it from the last field.
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                Text(
                  context.l10n.workspaceSetupIntro,
                  style: context.textTheme3.bodyMedium!.muted3(context),
                ),
                SizedBox(height: SdSpacingConstant.h24),
                SdTextFieldV3(
                  label: context.l10n.workspaceNameLabel,
                  controller: _name,
                  hint: context.l10n.workspaceNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.done,
                  onChanged: ref
                      .read(workspaceSetupControllerProvider.notifier)
                      .updateName,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCurrency,
                  isRequired: true,
                  icon: AppIconConstant.payments,
                  value: CurrencyLabel.of(context, state.currency),
                  onTap: _pickCurrency,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCountry,
                  isRequired: true,
                  icon: AppIconConstant.public,
                  value: CountryLabel.of(context, state.country),
                  onTap: _pickCountry,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceBusinessTypeOptional,
                  icon: AppIconConstant.badge,
                  value: state.businessType == null
                      ? null
                      : WorkspaceOptionLabel.businessType(
                          context,
                          state.businessType!,
                        ),
                  onTap: _pickBusinessType,
                ),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.workspaceCreate,
            isBusy: state.isSaving,
            onPressed: state.canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
