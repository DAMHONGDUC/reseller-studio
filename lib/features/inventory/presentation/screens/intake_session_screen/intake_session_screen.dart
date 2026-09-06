import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/constants/date_picker_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../core/widgets/picker_field.dart';
import '../../../../sourcing/domain/entities/source.dart';
import '../../../../sourcing/providers.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../../workspace/providers.dart';
import '../../controllers/intake_session_controller.dart';

part 'intake_session_screen_lines.dart';
part 'intake_session_screen_trip.dart';

/// Taking a whole buying trip in, one line at a time.
///
/// **The batch sibling of Quick Add.** A reseller comes back from a thrift
/// store with thirty things bought from one source on one day, and the cost of
/// each is the only figure that exists solely in that moment. Quick Add is
/// right for the single item found on a shelf and wrong for the car boot: it
/// asks for the source and the date once per item, which is thirty times, so
/// in practice nobody records either and every profit figure downstream is
/// `—`.
///
/// **The keyboard never closes.** Submitting the title box writes the item and
/// puts the cursor back in it, so the loop is type, tab, type, enter — and the
/// list of what has gone in builds up underneath without the seller ever
/// leaving the two fields.
///
/// **No new required field** (hard rule 2). The cost box is optional here
/// exactly as it is everywhere else; what changed is where it sits.
class IntakeSessionScreen extends ConsumerStatefulWidget {
  const IntakeSessionScreen({super.key});

  @override
  ConsumerState<IntakeSessionScreen> createState() =>
      _IntakeSessionScreenState();
}

class _IntakeSessionScreenState extends ConsumerState<IntakeSessionScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _receiptTotal = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The keyboard is up before the seller looks at the screen: they are
    // holding the thing they just bought, not reading a form.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _titleFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    _receiptTotal.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Writes one line and resets the two boxes, keeping the keyboard up.
  Future<void> _add() async {
    final String currency = ref.read(workspaceCurrencyProvider);
    final PlanBlock block = ref.read(addItemBlockProvider);

    if (block != PlanBlock.none) {
      await PlanBlockSheet.show(
        context,
        block: block,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    try {
      final bool added = await ref
          .read(intakeSessionControllerProvider.notifier)
          .add(
            title: _title.text,
            cost: Money.tryParse(_cost.text, currency),
          );

      if (!added || !mounted) return;

      _title.clear();
      _cost.clear();
      // Back to the title box rather than dismissing: the next thing out of
      // the bag is already in the seller's other hand.
      _titleFocus.requestFocus();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _finish() async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);

    try {
      await ref
          .read(intakeSessionControllerProvider.notifier)
          .finish(receiptTotal: Money.tryParse(_receiptTotal.text, currency));

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.intakeFinished);
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
    final IntakeSessionState state = ref.watch(intakeSessionControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.intakeTitle),
      body: Column(
        children: <Widget>[
          Expanded(child: _form(context, state, currency)),
          // Only once something has gone in: a Finish button over an empty
          // trip is an action that would write a purchase of nothing.
          if (state.lines.isNotEmpty)
            AppPinnedAction(
              label: context.l10n.intakeFinish(
                state.count,
                context.money(state.knownTotal),
              ),
              isBusy: state.isSaving,
              onPressed: state.isSaving ? null : _finish,
            ),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    IntakeSessionState state,
    String currency,
  ) => ListView(
        // No bottom inset: the pinned action owns the bottom edge.
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          _TripHeader(state: state),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: context.l10n.intakeItemTitle,
            controller: _title,
            focusNode: _titleFocus,
            isRequired: true,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          MoneyField(
            label: context.l10n.intakeItemCost,
            controller: _cost,
            currency: currency,
            // The whole reason this screen exists, said out loud: nobody
            // remembers a week later.
            helperText: context.l10n.intakeCostHelper,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.secondary,
            label: context.l10n.intakeAdd,
            icon: AppIconConstant.add,
            expand: true,
            busy: state.isSaving,
            onPressed: state.isSaving ? null : _add,
          ),
          if (state.lines.isNotEmpty) ...<Widget>[
            SizedBox(height: SdContentPaddingV3.sectionGap),
            MoneyField(
              label: context.l10n.intakeReceiptTotal,
              controller: _receiptTotal,
              currency: currency,
              // `Purchase.totalCost` is what left the pocket, and it is
              // allowed to disagree with the items — a box lot apportioned
              // across eleven things is the case it exists for.
              helperText: context.l10n.intakeReceiptTotalHelper,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: SdContentPaddingV3.sectionGap),
            _TakenIn(state: state),
          ],
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      );
}
