import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/state/form_seed.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../domain/entities/carrier.dart';
import '../../../providers.dart';
import '../../controllers/carrier_form_controller.dart';

class CarrierDetailScreen extends ConsumerStatefulWidget {
  const CarrierDetailScreen({this.carrierId, super.key});

  final String? carrierId;

  @override
  ConsumerState<CarrierDetailScreen> createState() =>
      _CarrierDetailScreenState();
}

class _CarrierDetailScreenState extends ConsumerState<CarrierDetailScreen>
    with FormSeed<CarrierDetailScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    if (_name.text.trim().isEmpty) return;

    try {
      final String? id = await ref
          .read(carrierFormControllerProvider.notifier)
          .submit(name: _name.text, carrierId: widget.carrierId);
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

  Future<void> _delete(String carrierId) async {
    final NavigatorState navigator = Navigator.of(context);
    try {
      await ref.read(carrierFormControllerProvider.notifier).delete(carrierId);
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

  Future<void> _confirmDelete(String carrierId) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.carrierDeleteTitle,
      message: context.l10n.carrierDeleteBody,
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.actionDelete,
          isDestructive: true,
          onPressed: () => _delete(carrierId),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool isSaving = ref.watch(carrierFormControllerProvider);
    final String? id = widget.carrierId;
    final AsyncValue<List<Carrier>> source = ref.watch(carriersProvider);
    final Carrier? existing = id == null
        ? null
        : source.value
              ?.where(
                (Carrier carrier) => carrier.id == id && !carrier.isDeleted,
              )
              .firstOrNull;

    if (id != null && !source.hasValue) return const SdLoadingV3Page();
    if (existing != null) seedOnce(() => _name.text = existing.name);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: id == null
            ? context.l10n.carrierAdd
            : context.l10n.carrierEditTitle,
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
                  label: context.l10n.carrierNameLabel,
                  controller: _name,
                  hint: context.l10n.carrierNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (String _) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: isSaving,
            onPressed: !isSaving && _name.text.trim().isNotEmpty
                ? _submit
                : null,
          ),
        ],
      ),
    );
  }
}
