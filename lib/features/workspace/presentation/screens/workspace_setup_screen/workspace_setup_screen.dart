import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../workspace_constant.dart';
import '../../controllers/workspace_setup_controller.dart';

/// Workspace setup — the step between signing up and Home (plan §26).
///
/// **Every business record lives under a workspace** (hard rule 14), so this
/// is not a settings screen a seller can skip: without one there is nowhere
/// to write an item. It asks for the three things plan §28 requires and
/// nothing else.
class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  ConsumerState<WorkspaceSetupScreen> createState() =>
      _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState
    extends ConsumerState<WorkspaceSetupScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: 'Currency',
      selected: ref.read(workspaceSetupControllerProvider).currency,
      options: WorkspaceConstant.currencies
          .map(
            (WorkspaceOption option) => PickerOption<String>(
              value: option.code,
              label: option.label,
              caption: option.code,
            ),
          )
          .toList(),
    );

    if (code == null) return;

    ref.read(workspaceSetupControllerProvider.notifier).selectCurrency(code);
  }

  Future<void> _pickCountry() async {
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: 'Country',
      selected: ref.read(workspaceSetupControllerProvider).country,
      options: WorkspaceConstant.countries
          .map(
            (WorkspaceOption option) =>
                PickerOption<String>(value: option.code, label: option.label),
          )
          .toList(),
    );

    if (code == null) return;

    ref.read(workspaceSetupControllerProvider.notifier).selectCountry(code);
  }

  Future<void> _pickBusinessType() async {
    final String? type = await OptionPickerSheet.show<String>(
      context,
      title: 'Business type',
      selected: ref.read(workspaceSetupControllerProvider).businessType,
      options: WorkspaceConstant.businessTypes
          .map(
            (String value) =>
                PickerOption<String>(value: value, label: value),
          )
          .toList(),
    );

    if (type == null) return;

    ref
        .read(workspaceSetupControllerProvider.notifier)
        .selectBusinessType(type);
  }

  /// Creates the workspace and stops. The router watches
  /// `workspaceStatusProvider` and moves the seller to Home by itself.
  Future<void> _submit() async {
    try {
      await ref.read(workspaceSetupControllerProvider.notifier).submit();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceSetupState state = ref.watch(
      workspaceSetupControllerProvider,
    );

    return SdScaffoldV3(
      appBar: const SdAppBarV3(
        title: 'Set up your business',
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Text(
            'Everything you track lives under a business. You can rename it '
            'later; the currency you pick is what every figure is reported in.',
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdTextFieldV3(
            label: 'Business name',
            controller: _name,
            hint: 'Duc Vintage',
            textInputAction: TextInputAction.done,
            onChanged: ref
                .read(workspaceSetupControllerProvider.notifier)
                .updateName,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: 'Currency',
            icon: Symbols.payments_rounded,
            value: WorkspaceConstant.labelFor(
              WorkspaceConstant.currencies,
              state.currency,
            ),
            onTap: _pickCurrency,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: 'Country',
            icon: Symbols.public_rounded,
            value: WorkspaceConstant.labelFor(
              WorkspaceConstant.countries,
              state.country,
            ),
            onTap: _pickCountry,
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: 'Business type (optional)',
            icon: Symbols.badge_rounded,
            value: state.businessType,
            onTap: _pickBusinessType,
          ),
          SizedBox(height: SdSpacingConstant.h32),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Create business',
            expand: true,
            busy: state.isSaving,
            onPressed: state.canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
