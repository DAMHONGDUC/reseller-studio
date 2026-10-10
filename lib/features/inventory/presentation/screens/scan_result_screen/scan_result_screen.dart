import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/constants/log_tag_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../../core/widgets/item_card.dart';
import '../../../../listings/domain/entities/listing.dart';
import '../../../../listings/providers.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/scan_match.dart';
import '../../../providers.dart';
import '../../widgets/item_actions_sheet.dart';
import '../../widgets/item_quick_actions.dart';

part 'scan_result_screen_code.dart';
part 'scan_result_screen_item.dart';
part 'scan_result_screen_location.dart';
part 'scan_result_screen_none.dart';

/// What a scanned code named, and the next step from it (plan §7).
///
/// **A screen rather than a dialog over the camera**, so the answer has room
/// for the item itself and every action on it — a seller holding the thing
/// mostly wants to sell it, reprice it or move it, not only open it.
///
/// Pushed over the scanner, which pauses its camera meanwhile: back and
/// Scan again both return to a camera ready for the next code.
class ScanResultScreen extends ConsumerWidget {
  const ScanResultScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScanMatch? match = ref.watch(scanMatchProvider(code));

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.scanResultTitle),
      body: match == null
          ? const Center(child: SdLoadingV3())
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    // No bottom inset: the pinned action owns the bottom edge.
                    padding: EdgeInsets.symmetric(
                      horizontal: SdContentPaddingV3.horizontal,
                    ),
                    children: <Widget>[
                      SizedBox(height: SdContentPaddingV3.topGap),
                      _ScannedCode(match: match),
                      switch (match) {
                        ScanMatchItem(:final Item item) => _ItemResult(
                          item: item,
                        ),
                        ScanMatchLocation() => _LocationResult(match: match),
                        ScanMatchNone() => _NoMatchResult(code: match.code),
                      },
                      SizedBox(height: SdContentPaddingV3.bottomGap),
                    ],
                  ),
                ),
                AppPinnedAction(
                  label: context.l10n.scannerScanAgain,
                  icon: AppIconConstant.barcodeScanner,
                  onPressed: () {
                    SdLogger.action(LogTagConstant.scanner, 'Scan again');
                    context.pop();
                  },
                ),
              ],
            ),
    );
  }
}
