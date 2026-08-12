import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../../core/widgets/receipt_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/source.dart';
import '../../providers.dart';
import '../controllers/sourcing_controller.dart';

/// Record a buying trip (plan §28).
///
/// **The date is the only required field.** A source is optional because a
/// seller may record what they bought before recording where, and the total is
/// optional because the receipt is sometimes still in a coat pocket.
class PurchaseFormSheet extends ConsumerStatefulWidget {
  const PurchaseFormSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => const PurchaseFormSheet(),
      );

  @override
  ConsumerState<PurchaseFormSheet> createState() => _PurchaseFormSheetState();
}

class _PurchaseFormSheetState extends ConsumerState<PurchaseFormSheet> {
  /// How far back the date picker opens. Five years covers the tax records a
  /// reseller keeps.
  static const int pickerYearsBack = 5;

  final TextEditingController _total = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  /// Minted here so a receipt uploaded before the purchase is saved already
  /// lands under the record it belongs to.
  final String _purchaseId = const Uuid().v4();

  DateTime _date = DateTime.now();
  String? _sourceId;
  String? _receiptUrl;

  @override
  void dispose() {
    _total.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _attach({required bool fromCamera}) async {
    try {
      final String? url = await ref
          .read(sourcingControllerProvider.notifier)
          .attachReceipt(recordId: _purchaseId, fromCamera: fromCamera);

      // Null means the seller cancelled the picker, which is not a change.
      if (url == null || !mounted) return;

      setState(() => _receiptUrl = url);
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref
          .read(sourcingControllerProvider.notifier)
          .savePurchase(
            id: _purchaseId,
            purchaseDate: _date,
            sourceId: _sourceId,
            totalCost: _total.text,
            notes: _notes.text,
            receiptUrl: _receiptUrl,
          );

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, 'Purchase recorded');
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(sourcingControllerProvider);
    final List<Source> sources =
        ref.watch(sourcesProvider).value ?? const <Source>[];
    final Map<String, String> names = ref.watch(sourceNamesProvider);
    final DateTime now = DateTime.now();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SdBottomSheetV3(
        title: 'New purchase',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PickerField(
              label: 'Date',
              icon: Symbols.calendar_month_rounded,
              value: DateTimeUtils.mediumDate(
                _date,
                locale: context.localeTag,
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(now.year - pickerYearsBack),
                  // A purchase cannot be from next month, and one filed there
                  // breaks every period report it lands in.
                  lastDate: now,
                );

                if (picked == null) return;

                setState(() => _date = picked);
              },
            ),
            SizedBox(height: SdSpacingConstant.h16),
            PickerField(
              label: 'Source (optional)',
              icon: Symbols.storefront_rounded,
              value: names[_sourceId],
              placeholder: sources.isEmpty ? 'None yet' : 'Not set',
              onTap: sources.isEmpty
                  ? () => SdSnackBarUtilsV3.info(
                      context,
                      'Add a source first: Sourcing → Sources',
                    )
                  : () async {
                      final String? picked =
                          await OptionPickerSheet.show<String>(
                            context,
                            title: 'Source',
                            selected: _sourceId,
                            options: sources
                                .map(
                                  (Source source) => PickerOption<String>(
                                    value: source.id,
                                    label: source.name,
                                  ),
                                )
                                .toList(),
                          );

                      if (picked == null) return;

                      setState(() => _sourceId = picked);
                    },
            ),
            SizedBox(height: SdSpacingConstant.h16),
            MoneyField(
              label: 'Total paid (optional)',
              controller: _total,
              currency: ref.watch(workspaceCurrencyProvider),
              helperText: 'What the receipt says, not the sum of the items',
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            SdTextFieldV3(
              label: 'Notes (optional)',
              controller: _notes,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            ReceiptField(
              url: _receiptUrl,
              isBusy: isBusy,
              onCamera: () => _attach(fromCamera: true),
              onLibrary: () => _attach(fromCamera: false),
              onRemove: () => setState(() => _receiptUrl = null),
            ),
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.actionSave,
              expand: true,
              busy: isBusy,
              onPressed: isBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
