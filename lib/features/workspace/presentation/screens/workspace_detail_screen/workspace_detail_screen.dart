import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../country_label.dart';
import '../../../country_picker.dart';
import '../../../domain/entities/workspace.dart';
import '../../../providers.dart';
import '../../../workspace_constant.dart';
import '../../../workspace_option_label.dart';
import '../../controllers/workspace_detail_controller.dart';

part 'workspace_detail_screen_danger.dart';

/// The one screen that changes a business.
///
/// Reached from the switcher sheet and from Settings (owner's rule,
/// `lib/features/workspace/CLAUDE.md`), which is why it takes an id rather
/// than reading the current workspace: the switcher can open it on a business
/// the seller is not standing in.
///
/// **A form with a pinned save, not a row that writes on tap.** Settings used
/// to open a picker per row and save on the tap; correcting the country and
/// the currency together was two writes and two messages.
class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  const WorkspaceDetailScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  final TextEditingController _name = TextEditingController();

  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Once. The provider outlives one visit to the form, so a second business
  /// opened after a first would otherwise inherit its country.
  void _seed(Workspace workspace) {
    if (_seeded) return;

    _seeded = true;
    _name.text = workspace.name;
    ref.read(workspaceDetailControllerProvider.notifier).seed(workspace);
  }

  Future<void> _pickCountry() async {
    final String? code = await CountryPicker.show(
      context,
      selected: ref.read(workspaceDetailControllerProvider).country,
    );

    if (code == null) return;

    ref.read(workspaceDetailControllerProvider.notifier).selectCountry(code);
  }

  Future<void> _pickCurrency() async {
    final String? code = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceCurrency,
      selected: ref.read(workspaceDetailControllerProvider).currency,
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

    ref.read(workspaceDetailControllerProvider.notifier).selectCurrency(code);
  }

  Future<void> _pickBusinessType() async {
    final String? key = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.workspaceBusinessType,
      selected: ref.read(workspaceDetailControllerProvider).businessType,
      options: WorkspaceConstant.businessTypes
          .map(
            (String key) => PickerOption<String>(
              value: key,
              label: WorkspaceOptionLabel.businessType(context, key),
            ),
          )
          .toList(),
    );

    if (key == null) return;

    ref
        .read(workspaceDetailControllerProvider.notifier)
        .selectBusinessType(key);
  }

  Future<void> _pickStaleThreshold() async {
    final int? days = await OptionPickerSheet.show<int>(
      context,
      title: context.l10n.workspaceStaleAfter,
      selected: ref.read(workspaceDetailControllerProvider).staleThresholdDays,
      options: WorkspaceConstant.staleThresholdChoices
          .map(
            (int days) => PickerOption<int>(
              value: days,
              label: context.l10n.workspaceStaleAfterDays(days),
            ),
          )
          .toList(),
    );

    if (days == null) return;

    ref
        .read(workspaceDetailControllerProvider.notifier)
        .selectStaleThresholdDays(days);
  }

  Future<void> _pickLowStock() async {
    final int? items = await OptionPickerSheet.show<int>(
      context,
      title: context.l10n.workspaceLowStock,
      selected: ref.read(workspaceDetailControllerProvider).lowStockThreshold,
      options: WorkspaceConstant.lowStockChoices
          .map(
            (int items) => PickerOption<int>(
              value: items,
              label: context.l10n.workspaceLowStockItems(items),
            ),
          )
          .toList(),
    );

    if (items == null) return;

    ref
        .read(workspaceDetailControllerProvider.notifier)
        .selectLowStockThreshold(items);
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      final bool saved = await ref
          .read(workspaceDetailControllerProvider.notifier)
          .submit();

      if (!saved || !mounted) return;

      // No success message: this is an edit that closes onto the card showing
      // the values it just wrote (owner's rule).
      navigator.pop();
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
    final Workspace? workspace = ref
        .watch(liveWorkspaceProvider(widget.workspaceId))
        .value;

    if (workspace == null) {
      return SdScaffoldV3(
        appBar: SdAppBarV3(title: context.l10n.workspaceDetailTitle),
        body: const Center(child: SdLoadingV3()),
      );
    }

    _seed(workspace);

    final WorkspaceDetailState state = ref.watch(
      workspaceDetailControllerProvider,
    );

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.workspaceDetailTitle,
        subtitle: workspace.name,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              // No bottom inset: the pinned action owns the bottom edge.
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                SdTextFieldV3(
                  label: context.l10n.workspaceNameLabel,
                  controller: _name,
                  hint: context.l10n.workspaceNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.done,
                  onChanged: ref
                      .read(workspaceDetailControllerProvider.notifier)
                      .updateName,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCountry,
                  isRequired: true,
                  icon: Symbols.public_rounded,
                  value: CountryLabel.of(context, state.country),
                  onTap: _pickCountry,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceCurrency,
                  isRequired: true,
                  icon: Symbols.payments_rounded,
                  value: WorkspaceOptionLabel.currency(context, state.currency),
                  onTap: _pickCurrency,
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
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceStaleAfter,
                  icon: Symbols.hourglass_bottom_rounded,
                  value: context.l10n.workspaceStaleAfterDays(
                    state.staleThresholdDays,
                  ),
                  onTap: _pickStaleThreshold,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                PickerField(
                  label: context.l10n.workspaceLowStock,
                  icon: Symbols.inventory_2_rounded,
                  value: context.l10n.workspaceLowStockItems(
                    state.lowStockThreshold,
                  ),
                  onTap: _pickLowStock,
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _DangerZone(workspace: workspace),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: state.isSaving,
            onPressed: state.canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
