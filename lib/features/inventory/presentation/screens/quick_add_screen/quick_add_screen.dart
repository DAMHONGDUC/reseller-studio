import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
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

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Saves, then leaves. The controller has already logged both outcomes, so
  /// this only decides what the seller sees.
  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String saved = context.l10n.quickAddSaved;

    try {
      final String? id = await ref
          .read(quickAddControllerProvider.notifier)
          .submit();

      if (id == null || !mounted) return;

      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    } catch (_) {
      // Already logged by the controller; the seller gets the one message
      // hard rule 6 allows.
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.errorGenericMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuickAddState state = ref.watch(quickAddControllerProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.quickAddTitle),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SdTextFieldV3(
            controller: _title,
            label: context.l10n.quickAddNameLabel,
            hint: context.l10n.quickAddNameHint,
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
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.actionSave,
            onPressed: state.canSubmit ? _submit : null,
            busy: state.isSaving,
            expand: true,
          ),
        ],
      ),
    );
  }
}
