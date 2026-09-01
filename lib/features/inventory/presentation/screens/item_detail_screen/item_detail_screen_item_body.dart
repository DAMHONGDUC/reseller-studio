part of 'item_detail_screen.dart';

/// The item, in blocks a seller can open one at a time.
///
/// **There is no edit screen any more** — the rule and its reasons are in
/// `docs/rules/SCREENS.md`. Each block shows its facts with an Edit; Edit
/// swaps the same rows for fields and puts Cancel and Save where Edit was.
///
/// **The boxes live here, the writing does not.** Text controllers are the
/// screen's, the way every other form in this app does it; which section is
/// open and what a save writes belong to `ItemDetailEditController`.
class _ItemBody extends ConsumerStatefulWidget {
  const _ItemBody({required this.item});

  final Item item;

  @override
  ConsumerState<_ItemBody> createState() => _ItemBodyState();
}

class _ItemBodyState extends ConsumerState<_ItemBody> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _minimum = TextEditingController();
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    _cost.dispose();
    _minimum.dispose();
    _barcode.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Fills this section's boxes from the record, then opens it.
  ///
  /// Seeding on every open rather than once per screen is what makes Cancel a
  /// restore: reopening reads what the record says now, so a teammate's edit
  /// in between is not overwritten by a stale draft.
  void _startEdit(ItemDetailSection section) {
    final Item item = widget.item;

    switch (section) {
      case ItemDetailSection.overview:
        _title.text = item.title;
        _quantity.text = item.quantity.toString();
      case ItemDetailSection.pricing:
        _cost.text = item.purchasePrice?.toInputString() ?? '';
        _minimum.text = item.minimumPrice?.toInputString() ?? '';
      case ItemDetailSection.provenance:
        _barcode.text = item.barcode ?? '';
      case ItemDetailSection.description:
        _description.text = item.description ?? '';
      case ItemDetailSection.notes:
        _notes.text = item.notes ?? '';
    }

    ref.read(itemDetailEditControllerProvider.notifier).edit(section, item);
  }

  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
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
    final Item item = widget.item;
    final ItemDetailEditState edit = ref.watch(
      itemDetailEditControllerProvider,
    );
    final ItemDetailEditController controller = ref.read(
      itemDetailEditControllerProvider.notifier,
    );
    final String currency = ref.watch(workspaceCurrencyProvider);

    return ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        if (item.photoUrls.isNotEmpty) ...<Widget>[
          _Photos(urls: item.photoUrls),
          SizedBox(height: SdContentPaddingV3.sectionGap),
        ],
        _Section(
          section: ItemDetailSection.overview,
          title: context.l10n.itemOverview,
          edit: edit,
          first: item.photoUrls.isEmpty,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          canSave: _title.text.trim().isNotEmpty,
          onSave: () => _save(
            () => controller.saveOverview(
              itemId: item.id,
              title: _title.text,
              quantity: _quantity.text,
            ),
          ),
          reading: _OverviewFacts(item: item),
          editing: Column(
            children: <Widget>[
              SdTextFieldV3(
                label: context.l10n.commonTitle,
                controller: _title,
                isRequired: true,
                textInputAction: TextInputAction.next,
                onChanged: (String _) => setState(() {}),
              ),
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.commonQuantity,
                controller: _quantity,
                isRequired: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              ItemConditionField(
                selected: edit.condition,
                onSelected: controller.selectCondition,
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _Section(
          section: ItemDetailSection.pricing,
          title: context.l10n.itemPricing,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.savePricing(
              itemId: item.id,
              purchasePrice: _cost.text,
              minimumPrice: _minimum.text,
            ),
          ),
          reading: _PricingFacts(item: item),
          editing: Column(
            children: <Widget>[
              MoneyField(
                label: context.l10n.itemCost,
                controller: _cost,
                currency: currency,
                helperText: context.l10n.itemCostHelp,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              MoneyField(
                label: context.l10n.itemMinimumPrice,
                controller: _minimum,
                currency: currency,
                helperText: context.l10n.itemMinimumPriceHelp,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _ListingsSection(item: item),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _Section(
          section: ItemDetailSection.provenance,
          title: context.l10n.itemProvenance,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.saveProvenance(
              itemId: item.id,
              barcode: _barcode.text,
            ),
          ),
          reading: _ProvenanceFacts(item: item),
          editing: Column(
            children: <Widget>[
              ItemSourceField(
                selected: edit.sourceId,
                onSelected: controller.selectSource,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              ItemPurchaseDateField(
                selected: edit.purchaseDate,
                onSelected: controller.selectPurchaseDate,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              ItemCategoryField(
                selected: edit.categoryId,
                onSelected: controller.selectCategory,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              ItemLocationField(
                selected: edit.locationId,
                onSelected: controller.selectLocation,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.commonBarcode,
                controller: _barcode,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _Section(
          section: ItemDetailSection.description,
          title: context.l10n.commonDescription,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.saveDescription(
              itemId: item.id,
              description: _description.text,
            ),
          ),
          reading: _LongText(value: item.description),
          editing: SdTextFieldV3(
            label: context.l10n.commonDescription,
            controller: _description,
            maxLines: 3,
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _Section(
          section: ItemDetailSection.notes,
          title: context.l10n.commonNotes,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.saveNotes(itemId: item.id, notes: _notes.text),
          ),
          reading: _LongText(value: item.notes),
          editing: SdTextFieldV3(
            label: context.l10n.itemFormPrivateNotes,
            controller: _notes,
            maxLines: 3,
          ),
        ),
        SizedBox(height: SdContentPaddingV3.bottomGap),
      ],
    );
  }
}

/// One editable block: the header and its two bodies, wrapped in the card.
///
/// It exists so the five call sites above pass what differs — the section,
/// its title and its two bodies — rather than repeating the card, the open
/// test and the "another section is already open" rule five times.
class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.title,
    required this.edit,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.reading,
    required this.editing,
    this.canSave = true,
    this.first = false,
  });

  final ItemDetailSection section;
  final String title;
  final ItemDetailEditState edit;
  final ValueChanged<ItemDetailSection> onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Widget reading;
  final Widget editing;
  final bool canSave;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final bool isOpen = edit.isOpen(section);

    return AppEditableSection(
      title: title,
      first: first,
      isEditing: isOpen,
      isSaving: isOpen && edit.isSaving,
      canSave: canSave,
      // Null while another block is open: one draft at a time, so there is
      // never a second set of unsaved keystrokes with its own Save.
      onEdit: edit.editing == null ? () => onEdit(section) : null,
      onCancel: onCancel,
      onSave: onSave,
      child: SdCardV3(child: isOpen ? editing : reading),
    );
  }
}

/// Title, state and grade — what the item is.
class _OverviewFacts extends StatelessWidget {
  const _OverviewFacts({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        item.title,
        style: context.textTheme3.titleMedium!.semiBold3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      Wrap(
        spacing: SdSpacingConstant.w6,
        runSpacing: SdSpacingConstant.h4,
        children: <Widget>[
          SdBadgeV3(
            label: item.status.label(context),
            color: item.status.color(context),
          ),
          if (item.condition != null)
            SdBadgeV3(
              label: item.condition!.label(context),
              color: item.condition!.color(context),
            ),
          if (item.quantity > 1)
            SdBadgeV3(label: context.l10n.itemQuantityTimes(item.quantity)),
        ],
      ),
    ],
  );
}

/// What it cost, and the floor the seller will not go under.
class _PricingFacts extends StatelessWidget {
  const _PricingFacts({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      _DetailRow(
        label: context.l10n.itemCost,
        value: context.money(item.purchasePrice),
      ),
      _DetailRow(
        label: context.l10n.itemMinimumPrice,
        value: context.money(item.minimumPrice),
      ),
    ],
  );
}

/// A block of prose the seller wrote, or the dash saying they have not.
///
/// **Drawn even when empty** — owner's rule. Description and Notes used to
/// disappear until they had content, which made the section a seller wanted
/// to *add* one to impossible to find.
class _LongText extends StatelessWidget {
  const _LongText({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      value ?? context.l10n.emptyValuePlaceholder,
      style: context.textTheme3.bodyMedium!.muted3(context),
    ),
  );
}
