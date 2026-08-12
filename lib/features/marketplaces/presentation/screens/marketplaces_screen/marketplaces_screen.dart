import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/enums/marketplace.dart';

/// Marketplaces — connection status, and nothing else (plan §14).
///
/// **No token ever reaches this screen, or this app.** OAuth and every call
/// that uses a token happen in a Cloud Function; `marketplaces/{id}` in
/// Firestore holds connection *status* only and is `allow write: if false`
/// (hard rule 10). The app asks the backend; the backend asks eBay.
///
/// Nothing is connected today because no function is deployed, and the screen
/// says so plainly rather than showing a Connect button that fails. The fee
/// rate shown is the platform's published estimate, used by the buy
/// calculator — never by an order, which carries the fee the platform
/// actually charged.
class MarketplacesScreen extends ConsumerWidget {
  const MarketplacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdScaffoldV3(
    appBar: const SdAppBarV3(title: 'Marketplaces'),
    body: ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        SdCardV3(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Syncing is not switched on yet',
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              SizedBox(height: SdSpacingConstant.h6),
              Text(
                'Connections run on the server so your marketplace passwords '
                'and tokens never touch this app. Until that is live, list '
                'and sell manually — everything else in Seller OS works the '
                'same either way.',
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        AppListCard(
          children: Marketplace.values
              .where(
                // "Other" is where a car-boot sale goes. It is not a platform
                // and there is nothing to connect it to.
                (Marketplace marketplace) => marketplace != Marketplace.other,
              )
              .map(
                (Marketplace marketplace) => AppListRow(
                  title: marketplace.displayName,
                  subtitle:
                      '${(marketplace.estimatedFeeRate * 100).toStringAsFixed(1)}% '
                      'estimated fee',
                  icon: Symbols.hub_rounded,
                  showChevron: false,
                  trailing: SdBadgeV3(
                    label: marketplace.hasIntegration
                        ? 'Connected'
                        : 'Coming soon',
                    tone: marketplace.hasIntegration
                        ? SdBadgeToneV3.success
                        : SdBadgeToneV3.neutral,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}
