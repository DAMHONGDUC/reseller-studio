import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../controllers/quick_add_controller.dart';

/// The fastest way to get something into inventory.
///
/// **One field, and it is the only one that is required** — hard rule 2 and
/// plan §28. A seller holding the object types what it is and leaves; price,
/// photos, category and source attach later, or never. Adding a second
/// required field here is the single easiest way to turn this app back into
/// the spreadsheet it replaces, and needs explicit approval.
///
/// The screen owns its `TextEditingController` and nothing else: the state and
/// the write live in [QuickAddController].
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final TextEditingController _title = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Saves and stays, so a seller holding three things types three titles.
  ///
  /// The cleared box is the confirmation — the same argument as the row
  /// appearing behind the sheet, and the reason there is still no success
  /// message here (owner's rule).
  Future<void> _submitAndContinue() async {
    if (await _save() == null) return;

    _title.clear();
    ref.read(quickAddControllerProvider.notifier).updateTitle('');
    _titleFocus.requestFocus();
  }

  /// Saves, then leaves. The controller has already logged both outcomes, so
  /// this only decides what the seller sees — which on success is nothing but
  /// the new row in the list behind (owner's rule).
  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    if (await _save() == null) return;

    navigator.pop();
  }

  /// Writes the item and returns its id, or null when nothing was written.
  ///
  /// Shared by both buttons, so the plan gate and the error message cannot
  /// differ between saving once and saving again.
  Future<String?> _save() async {
    final PlanBlock block = ref.read(addItemBlockProvider);

    if (block != PlanBlock.none) {
      await PlanBlockSheet.show(
        context,
        block: block,
        plan: ref.read(currentPlanProvider),
      );

      return null;
    }

    try {
      final String? id = await ref
          .read(quickAddControllerProvider.notifier)
          .submit();

      return mounted ? id : null;
    } catch (_) {
      // Already logged by the controller; the seller gets the one message
      // hard rule 6 allows.
      if (!mounted) return null;

      SdSnackBarUtilsV3.error(context, context.l10n.errorGenericMessage);

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuickAddState state = ref.watch(quickAddControllerProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.quickAddTitle),
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
                  controller: _title,
                  focusNode: _titleFocus,
                  label: context.l10n.quickAddNameLabel,
                  hint: context.l10n.quickAddNameHint,
                  isRequired: true,
                  // The field's own helper, not a Text under it: one control owns
                  // the message so it cannot drift out of the field's layout.
                  helperText: context.l10n.quickAddHelp,
                  textInputAction: TextInputAction.done,
                  onChanged: ref
                      .read(quickAddControllerProvider.notifier)
                      .updateTitle,
                  onSubmitted: (_) {
                    if (state.canSubmit) _submit();
                  },
                ),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: state.isSaving,
            onPressed: state.canSubmit ? _submit : null,
            // Above Save and quieter than it: the common case is one item,
            // and the button under the resting thumb stays the one that
            // finishes (`docs/rules/SCREENS.md`).
            secondary: SdButtonV3(
              variant: SdButtonVariantV3.outlined,
              label: context.l10n.quickAddSaveAndAnother,
              expand: true,
              onPressed: state.canSubmit ? _submitAndContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
