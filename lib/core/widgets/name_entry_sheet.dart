import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// A sheet that asks for one short string and hands it back.
///
/// Categories, locations, sources, shipping carriers — the app asks "what is
/// it called?" in half a dozen places, and every one of them is the same
/// sheet. In `core/widgets/` because more than one feature uses it.
///
/// Returns the trimmed text, or null when the seller dismissed it. **Null
/// means "left it alone", never "cleared it"** — a caller that treated a
/// dismissal as an empty name would wipe the field on every stray tap.
class NameEntrySheet extends StatefulWidget {
  const NameEntrySheet({
    required this.title,
    required this.label,
    this.initialValue,
    this.hint,
    this.confirmLabel,
    super.key,
  });

  final String title;
  final String label;
  final String? initialValue;
  final String? hint;

  /// Null falls back to the shared Save label — most callers want it, and a
  /// default cannot be a localized string because a parameter default is
  /// evaluated with no `BuildContext`.
  final String? confirmLabel;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    String? initialValue,
    String? hint,
    String? confirmLabel,
  }) => showSdBottomSheetV3<String>(
    context: context,
    builder: (BuildContext context) => NameEntrySheet(
      title: title,
      label: label,
      initialValue: initialValue,
      hint: hint,
      confirmLabel: confirmLabel,
    ),
  );

  @override
  State<NameEntrySheet> createState() => _NameEntrySheetState();
}

class _NameEntrySheetState extends State<NameEntrySheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();

    if (value.isEmpty) {
      SdSnackBarUtilsV3.error(context, context.l10n.commonNameRequired);

      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: widget.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdTextFieldV3(
          label: widget.label,
          controller: _controller,
          hint: widget.hint,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: SdSpacingConstant.h24),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: widget.confirmLabel ?? context.l10n.actionSave,
          expand: true,
          onPressed: _submit,
        ),
      ],
    ),
  );
}
