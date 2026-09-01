import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/state/form_seed.dart';
import '../../../../../core/theme/app_tag_hue.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../domain/entities/marketplace.dart';
import '../../../domain/services/marketplace_rate_input_utils.dart';
import '../../../providers.dart';
import '../../controllers/marketplace_form_controller.dart';
import '../../widgets/marketplace_hue_field.dart';

/// Adds a marketplace or edits one seller-owned marketplace record.
///
/// Name, estimated fee rate, and deletion live here together. The list only
/// opens this screen, so there is one editing surface for the record.
class MarketplaceDetailScreen extends ConsumerStatefulWidget {
  const MarketplaceDetailScreen({this.marketplaceId, super.key});

  /// Null to add, set to edit.
  final String? marketplaceId;

  @override
  ConsumerState<MarketplaceDetailScreen> createState() =>
      _MarketplaceDetailScreenState();
}

class _MarketplaceDetailScreenState
    extends ConsumerState<MarketplaceDetailScreen>
    with FormSeed<MarketplaceDetailScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _percent = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.marketplaceId == null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        ref.read(marketplaceFormControllerProvider.notifier).startCreate();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _percent.dispose();
    super.dispose();
  }

  void _seed(Marketplace marketplace) {
    _name.text = marketplace.name;
    _percent.text = (marketplace.feeRate * 100).toStringAsFixed(2);
    ref.read(marketplaceFormControllerProvider.notifier).seed(marketplace);
  }

  void _updateRate(String value) {
    final String trimmed = value.trim();

    ref
        .read(marketplaceFormControllerProvider.notifier)
        .updateFeeRate(
          trimmed.isEmpty
              ? null
              : MarketplaceRateInputUtils.parse(trimmed) ?? -1,
        );
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    if (_name.text.trim().isEmpty) {
      SdSnackBarUtilsV3.error(context, context.l10n.marketplaceNameRequired);

      return;
    }

    try {
      final String? id = await ref
          .read(marketplaceFormControllerProvider.notifier)
          .submit(name: _name.text, marketplaceId: widget.marketplaceId);

      if (id == null || !mounted) return;

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

  Future<void> _confirmDelete(String marketplaceId) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.marketplaceDeleteTitle,
        message: context.l10n.marketplaceDeleteBody,
        icon: AppIconConstant.warning,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () => _delete(marketplaceId),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  Future<void> _delete(String marketplaceId) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref
          .read(marketplaceFormControllerProvider.notifier)
          .delete(marketplaceId);

      if (!mounted) return;

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
    final MarketplaceFormState state = ref.watch(
      marketplaceFormControllerProvider,
    );
    final String? id = widget.marketplaceId;
    final AsyncValue<List<Marketplace>> source = ref.watch(
      marketplacesProvider,
    );
    final Marketplace? existing = id == null
        ? null
        : source.value
              ?.where((Marketplace row) => row.id == id && !row.isDeleted)
              .firstOrNull;

    if (id != null && !source.hasValue) return const SdLoadingV3Page();
    if (existing != null) seedOnce(() => _seed(existing));

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: id == null
            ? context.l10n.marketplaceAdd
            : context.l10n.marketplaceEditTitle,
        actions: <Widget>[
          if (id != null)
            SdAppBarActionButtonV3(
              icon: AppIconConstant.delete,
              tooltip: context.l10n.actionDelete,
              tint: context.sdTheme3.danger,
              onPressed: state.isSaving ? null : () => _confirmDelete(id),
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
                  label: context.l10n.marketplaceNameLabel,
                  controller: _name,
                  hint: context.l10n.marketplaceNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (String _) => setState(() {}),
                ),
                SizedBox(height: SdSpacingConstant.h16),
                SdTextFieldV3(
                  label: context.l10n.marketplaceFeeLabel,
                  controller: _percent,
                  isRequired: true,
                  suffix: Text(
                    '%',
                    style: context.textTheme3.bodyMedium!.muted3(context),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  helperText: context.l10n.marketplaceFeeHelper,
                  errorText: state.feeRate == null || state.isFeeRateValid
                      ? null
                      : context.l10n.marketplaceFeeInvalid,
                  textInputAction: TextInputAction.done,
                  onChanged: _updateRate,
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: SdSpacingConstant.h16),
                MarketplaceHueField(
                  label: context.l10n.marketplaceColorLabel,
                  helperText: context.l10n.marketplaceColorHelper,
                  selected: state.hue,
                  onSelected: (AppTagHue hue) => ref
                      .read(marketplaceFormControllerProvider.notifier)
                      .selectHue(hue),
                ),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: state.isSaving,
            onPressed: state.canSubmit && _name.text.trim().isNotEmpty
                ? _submit
                : null,
          ),
        ],
      ),
    );
  }
}
