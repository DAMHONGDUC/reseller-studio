import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../workspace_constant.dart';
import '../../../workspace_option_label.dart';
import '../../controllers/workspace_setup_controller.dart';

part 'workspace_setup_screen_actions.dart';

/// Workspace setup — the step between signing in and Home (plan §26).
///
/// **Every business record lives under a workspace** (hard rule 14), so this
/// is not a settings screen a seller can skip: without one there is nowhere
/// to write an item. It asks for the three things plan §28 requires and
/// nothing else.
///
/// **The create action is pinned to the bottom** (owner's rule) — only the
/// form scrolls. See [_PinnedCreateAction].
class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({super.key});

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
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceCurrency,
      selected: ref.read(workspaceSetupControllerProvider).currency,
      options: WorkspaceConstant.currencies
          .map(
            (String code) => PickerOption<String>(
              value: code,
              label: WorkspaceOptionLabel.currency(context, code),
              caption: code,
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
      title: context.l10n.workspaceCountry,
      selected: ref.read(workspaceSetupControllerProvider).country,
      options: WorkspaceConstant.countries
          .map(
            (String code) => PickerOption<String>(
              value: code,
              label: WorkspaceOptionLabel.country(context, code),
            ),
          )
          .toList(),
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

  /// Creates the workspace and stops. The router watches
  /// `workspaceStatusProvider` and moves the seller to Home by itself.
  Future<void> _submit() async {
    try {
      await ref.read(workspaceSetupControllerProvider.notifier).submit();
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
        title: context.l10n.workspaceSetupTitle,
        automaticallyImplyLeading: false,
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
                  textInputAction: TextInputAction.done,
                  onChanged: ref
                      .read(workspaceSetupControllerProvider.notifier)
                      .updateName,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCurrency,
                  icon: Symbols.payments_rounded,
                  value: WorkspaceOptionLabel.currency(context, state.currency),
                  onTap: _pickCurrency,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCountry,
                  icon: Symbols.public_rounded,
                  value: WorkspaceOptionLabel.country(context, state.country),
                  onTap: _pickCountry,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceBusinessTypeOptional,
                  icon: Symbols.badge_rounded,
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
          _PinnedCreateAction(onSubmit: _submit),
        ],
      ),
    );
  }
}
