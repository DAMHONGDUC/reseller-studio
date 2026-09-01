import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// One block of a detail screen that can be edited without leaving it.
///
/// **The section is the unit of editing** — the rule and its reasons are in
/// `docs/rules/SCREENS.md`. Read mode shows the facts and an Edit; edit mode
/// shows the same rows as fields, with Cancel and Save in the same place Edit
/// was.
///
/// In `core/widgets/` because Item detail and Order detail both build it, and
/// anything else with a detail screen will too.
///
/// **It holds no state and decides nothing.** Which section is open and what
/// a save writes belong to a controller; this widget is the header, the two
/// buttons and whichever body it was handed.
class AppEditableSection extends StatelessWidget {
  const AppEditableSection({
    required this.title,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.child,
    this.isSaving = false,
    this.canSave = true,
    this.first = false,
    super.key,
  });

  final String title;
  final bool isEditing;

  /// Null while another section is open, which is what stops two drafts
  /// existing at once — the button greys rather than disappearing, so the
  /// seller can see that editing is possible and that something else is in
  /// the way.
  final VoidCallback? onEdit;

  final VoidCallback onCancel;
  final VoidCallback onSave;

  /// The body: the facts in read mode, the fields in edit mode. The caller
  /// swaps it, because only the caller knows what a row of this section is.
  final Widget child;

  final bool isSaving;

  /// False while the draft could not be written — an empty required box.
  final bool canSave;

  final bool first;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SdSectionHeaderV3(
        title: title,
        first: first,
        // The block is already inside the screen's gutter, so the heading
        // pays it once rather than twice.
        gutter: false,
        action: isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SdButtonV3(
                    variant: SdButtonVariantV3.text,
                    label: context.l10n.actionCancel,
                    size: SdButtonSizeV3.small,
                    onPressed: isSaving ? null : onCancel,
                  ),
                  SdButtonV3(
                    variant: SdButtonVariantV3.text,
                    label: context.l10n.actionSave,
                    size: SdButtonSizeV3.small,
                    busy: isSaving,
                    onPressed: canSave ? onSave : null,
                  ),
                ],
              )
            : SdButtonV3(
                variant: SdButtonVariantV3.text,
                label: context.l10n.actionEdit,
                icon: AppIconConstant.edit,
                size: SdButtonSizeV3.small,
                onPressed: onEdit,
              ),
      ),
      child,
    ],
  );
}
