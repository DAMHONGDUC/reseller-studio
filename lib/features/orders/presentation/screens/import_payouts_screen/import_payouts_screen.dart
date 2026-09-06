import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/services/payout_csv_import.dart';
import '../../../orders_import_constant.dart';
import '../../../providers.dart';
import '../../controllers/order_actions_controller.dart';

/// Fill the payout queue from a marketplace's own export.
///
/// **The fastest honest way to get the figures in.** The app measures a fee
/// rather than guessing it (hard rule 3), and every platform publishes what it
/// paid — so the work this creates is copying, and a file copies hundreds of
/// rows at once.
///
/// **A file the seller exported, never a connection.** No OAuth, no token, no
/// sync (hard rule 10): the app reads text the seller hands it and nothing
/// leaves the device on its account.
///
/// **Text pasted rather than a file picked**, deliberately: choosing a file
/// needs a third-party plugin, and adding one is the owner's call
/// (root `CLAUDE.md`). Paste works today with what already ships.
///
/// **Nothing is written until the seller sees what matched.** An import that
/// silently wrote money would be the same mistake as an estimated fee — a
/// number nobody can tell from one they entered.
class ImportPayoutsScreen extends ConsumerStatefulWidget {
  const ImportPayoutsScreen({super.key});

  @override
  ConsumerState<ImportPayoutsScreen> createState() =>
      _ImportPayoutsScreenState();
}

class _ImportPayoutsScreenState extends ConsumerState<ImportPayoutsScreen> {
  final TextEditingController _csv = TextEditingController();

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Order> queue, Map<String, Money> payouts) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .recordManySettlements(queue, payouts);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.recordPayoutsDone(payouts.length),
      );
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
    final List<Order> queue = ref.watch(ordersAwaitingPayoutListProvider);
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final String pasted = _csv.text.trim();

    final PayoutCsvResult read = pasted.isEmpty
        ? const PayoutCsvResult.unreadable()
        : PayoutCsvImport.parse(_csv.text, currency: currency);
    final PayoutCsvMatch match = PayoutCsvImport.against(queue, read.rows);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.importPayoutsTitle),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                Text(
                  context.l10n.importPayoutsIntro,
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
                SizedBox(height: SdSpacingConstant.h16),
                SdTextFieldV3(
                  label: context.l10n.importPayoutsPasteLabel,
                  controller: _csv,
                  hint: context.l10n.importPayoutsPasteHint,
                  maxLines: OrdersImportConstant.pasteRows,
                  onChanged: (String _) => setState(() {}),
                ),
                SizedBox(height: SdSpacingConstant.h16),
                if (pasted.isNotEmpty) _ReadSummary(read: read, match: match),
                SizedBox(height: SdContentPaddingV3.bottomGap),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.recordPayoutsSubmit(match.matchedCount),
            isBusy: isBusy,
            onPressed: isBusy || match.matchedCount == 0
                ? null
                : () => _submit(queue, match.payoutsByOrderId),
          ),
        ],
      ),
    );
  }
}

/// What the file turned out to say, before anything is written.
///
/// **It names the two columns it read.** A number written into a seller's books
/// from a column they cannot see chosen is a number they cannot check, and this
/// import exists precisely because guessed money is worse than none.
class _ReadSummary extends StatelessWidget {
  const _ReadSummary({required this.read, required this.match});

  final PayoutCsvResult read;
  final PayoutCsvMatch match;

  @override
  Widget build(BuildContext context) {
    if (!read.isReadable) {
      return SdCardV3(
        layer: SdCardLayerV3.sunken,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SdIconV3(
              AppIconConstant.info,
              size: SdIconV3.smallSize,
              color: context.sdTheme3.textTertiary,
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Expanded(
              child: Text(
                context.l10n.importPayoutsUnreadable,
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdStatTileV3(
          label: context.l10n.importPayoutsMatched,
          value: '${match.matchedCount}',
          caption: context.l10n.importPayoutsColumns(
            read.orderIdColumn!,
            read.payoutColumn!,
          ),
          icon: AppIconConstant.checkCircle,
          tone: match.matchedCount > 0
              ? SdStatToneV3.profit
              : SdStatToneV3.neutral,
        ),
        // Only when there is something to say: a clean file must not carry a
        // row of zeroes explaining what did not go wrong.
        if (match.unmatched.isNotEmpty || read.skipped > 0) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            context.l10n.importPayoutsLeftOver(
              match.unmatched.length,
              read.skipped,
            ),
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ],
    );
  }
}
