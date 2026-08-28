import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/date_picker_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_photo.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../../sourcing/domain/entities/source.dart';
import '../../../../sourcing/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/item_category.dart';
import '../../../domain/entities/storage_location.dart';
import '../../../domain/enums/item_status.dart';
import '../../../item_label.dart';
import '../../../providers.dart';
import '../../controllers/item_form_controller.dart';

part 'item_form_screen_photo_strip.dart';
part 'item_form_screen_sections.dart';

/// Add Item and Edit Item — one screen, because they are the same fields
/// (plan §7).
///
/// **Only the title is required** (hard rule 2). The form is long because a
/// seller filing stock at a desk wants every field in one place; it is not
/// long because any of it is compulsory, and Quick Add exists for the other
/// case.
///
/// The screen owns its text controllers and seeds them once when an edited
/// item arrives. Everything typed is handed to [ItemFormController] at
/// submit — parsing money and building the entity is not a widget's job.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({this.itemId, super.key});

  /// Null to create, set to edit.
  final String? itemId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _sku = TextEditingController();
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _asking = TextEditingController();
  final TextEditingController _minimum = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  /// Guards the one-time seed. The item arrives asynchronously and rebuilds
  /// afterwards; re-seeding on each of those would throw away every keystroke
  /// the seller had made in between.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();

    if (widget.itemId == null) {
      // The provider outlives one visit to the form, so a create started
      // after an edit would otherwise inherit that item's category.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(itemFormControllerProvider.notifier).startCreate();
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    _sku.dispose();
    _barcode.dispose();
    _cost.dispose();
    _asking.dispose();
    _minimum.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(Item item) {
    if (_seeded) return;

    _seeded = true;
    _title.text = item.title;
    _quantity.text = '${item.quantity}';
    _sku.text = item.sku ?? '';
    _barcode.text = item.barcode ?? '';
    _cost.text = item.purchasePrice?.toInputString() ?? '';
    _asking.text = item.askingPrice?.toInputString() ?? '';
    _minimum.text = item.minimumPrice?.toInputString() ?? '';
    _description.text = item.description ?? '';
    _notes.text = item.notes ?? '';
    ref.read(itemFormControllerProvider.notifier).seed(item);
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    if (_title.text.trim().isEmpty) {
      SdSnackBarUtilsV3.error(context, context.l10n.quickAddEmptyTitleError);

      return;
    }

    try {
      final String? id = await ref
          .read(itemFormControllerProvider.notifier)
          .submit(
            title: _title.text,
            quantity: _quantity.text,
            sku: _sku.text,
            barcode: _barcode.text,
            purchasePrice: _cost.text,
            askingPrice: _asking.text,
            minimumPrice: _minimum.text,
            description: _description.text,
            notes: _notes.text,
          );

      if (id == null || !mounted) return;

      // No success message: the screen closes onto the row that just changed,
      // which is the confirmation (owner's rule).
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
    final ItemFormState state = ref.watch(itemFormControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final String? editingId = widget.itemId;

    if (editingId != null) {
      final Item? existing = ref.watch(itemProvider(editingId)).value;

      if (existing != null) _seed(existing);
    }

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: state.isEditing
            ? context.l10n.itemFormEditTitle
            : context.l10n.inventoryAddItem,
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
                const _PhotoStrip(),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.itemFormBasics,
                  children: <Widget>[
                    SdTextFieldV3(
                      label: context.l10n.commonTitle,
                      controller: _title,
                      hint: context.l10n.quickAddNameHint,
                      isRequired: true,
                      helperText: context.l10n.itemFormOnlyRequired,
                      textInputAction: TextInputAction.next,
                    ),
                    SdTextFieldV3(
                      label: context.l10n.commonQuantity,
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    _ConditionField(state: state),
                    _CategoryField(state: state),
                  ],
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.itemPricing,
                  children: <Widget>[
                    MoneyField(
                      label: context.l10n.itemCost,
                      controller: _cost,
                      currency: currency,
                      helperText: context.l10n.itemCostHelp,
                      textInputAction: TextInputAction.next,
                    ),
                    MoneyField(
                      label: context.l10n.itemAskingPrice,
                      controller: _asking,
                      currency: currency,
                      textInputAction: TextInputAction.next,
                    ),
                    MoneyField(
                      label: context.l10n.itemMinimumPrice,
                      controller: _minimum,
                      currency: currency,
                      helperText: context.l10n.itemMinimumPriceHelp,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.itemFormWhereFrom,
                  children: <Widget>[
                    _SourceField(state: state),
                    _PurchaseDateField(state: state),
                  ],
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.itemFormWhereIs,
                  children: <Widget>[_LocationField(state: state)],
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.itemFormIdentifiers,
                  children: <Widget>[
                    SdTextFieldV3(
                      label: context.l10n.commonSku,
                      controller: _sku,
                      textInputAction: TextInputAction.next,
                    ),
                    SdTextFieldV3(
                      label: context.l10n.commonBarcode,
                      controller: _barcode,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                _FormSection(
                  title: context.l10n.commonNotes,
                  children: <Widget>[
                    SdTextFieldV3(
                      label: context.l10n.commonDescription,
                      controller: _description,
                      maxLines: 3,
                    ),
                    SdTextFieldV3(
                      label: context.l10n.itemFormPrivateNotes,
                      controller: _notes,
                      maxLines: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.actionSave,
            isBusy: state.isSaving,
            onPressed: state.isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
