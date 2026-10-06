import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// Ask for one name, without leaving what the seller is doing.
///
/// **Why it exists: a picker with nothing in it was a dead end.** The item
/// form's category and location fields said "None yet — add one in More",
/// which sends someone mid-form to another screen and loses what they had
/// typed. Creating the record here and selecting it is the same two taps
/// without the detour.
///
/// One field and nothing else on purpose: anything a record needs beyond a
/// name belongs on its own screen, and asking for it here would rebuild that
/// screen inside a sheet.
class NamePromptSheet extends StatefulWidget {
  const NamePromptSheet({
    required this.title,
    required this.label,
    required this.submitLabel,
    super.key,
  });

  final String title;
  final String label;
  final String submitLabel;

  /// The typed name, or null when the seller dismissed the sheet.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    required String submitLabel,
  }) => showSdBottomSheetV3<String>(
    context: context,
    builder: (BuildContext context) =>
        NamePromptSheet(title: title, label: label, submitLabel: submitLabel),
  );

  @override
  State<NamePromptSheet> createState() => _NamePromptSheetState();
}

class _NamePromptSheetState extends State<NamePromptSheet> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final String trimmed = _name.text.trim();

    if (trimmed.isEmpty) return;

    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return SdBottomSheetV3(
      title: widget.title,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdTextFieldV3(
            label: widget.label,
            controller: _name,
            isRequired: true,
            textInputAction: TextInputAction.done,
            onChanged: (String _) => setState(() {}),
            onSubmitted: (String _) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: widget.submitLabel,
            expand: true,
            onPressed: _name.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
