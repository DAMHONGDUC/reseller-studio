import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_photo.dart';
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
    _cost.text = _majorUnits(item.purchasePrice?.minor);
    _asking.text = _majorUnits(item.askingPrice?.minor);
    _minimum.text = _majorUnits(item.minimumPrice?.minor);
    _description.text = item.description ?? '';
    _notes.text = item.notes ?? '';
    ref.read(itemFormControllerProvider.notifier).seed(item);
  }

  /// Minor units back into something a person types: `1999` → `19.99`.
  ///
  /// Two decimals unconditionally, because the field is parsed back with
  /// `Money.tryParse`, which assumes them. A zero-decimal currency is a
  /// known gap and is listed in the release notes rather than half-handled
  /// here.
  static String _majorUnits(int? minor) {
    if (minor == null) return '';

    return (minor / 100).toStringAsFixed(2);
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

      navigator.pop();
      SdSnackBarUtilsV3.success(context, 'Saved');
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
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
        title: state.isEditing ? 'Edit item' : 'Add item',
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _PhotoStrip(),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _FormSection(
            title: 'Basics',
            children: <Widget>[
              SdTextFieldV3(
                label: 'Title',
                controller: _title,
                hint: 'Nike Air Max 90, size 10',
                helperText: 'The only field this needs',
                textInputAction: TextInputAction.next,
              ),
              SdTextFieldV3(
                label: 'Quantity',
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
            title: 'Pricing',
            children: <Widget>[
              MoneyField(
                label: 'Cost',
                controller: _cost,
                currency: currency,
                helperText: 'What you paid. Leave empty if you do not know.',
                textInputAction: TextInputAction.next,
              ),
              MoneyField(
                label: 'Asking price',
                controller: _asking,
                currency: currency,
                textInputAction: TextInputAction.next,
              ),
              MoneyField(
                label: 'Minimum price',
                controller: _minimum,
                currency: currency,
                helperText: 'The floor for offers and bulk repricing',
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _FormSection(
            title: 'Where it came from',
            children: <Widget>[
              _SourceField(state: state),
              _PurchaseDateField(state: state),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _FormSection(
            title: 'Where it is',
            children: <Widget>[_LocationField(state: state)],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _FormSection(
            title: 'Identifiers',
            children: <Widget>[
              SdTextFieldV3(
                label: 'SKU',
                controller: _sku,
                textInputAction: TextInputAction.next,
              ),
              SdTextFieldV3(
                label: 'Barcode',
                controller: _barcode,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _FormSection(
            title: 'Notes',
            children: <Widget>[
              SdTextFieldV3(
                label: 'Description',
                controller: _description,
                maxLines: 3,
              ),
              SdTextFieldV3(
                label: 'Private notes',
                controller: _notes,
                maxLines: 3,
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h32),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.actionSave,
            expand: true,
            busy: state.isSaving,
            onPressed: state.isSaving ? null : _submit,
          ),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }
}
