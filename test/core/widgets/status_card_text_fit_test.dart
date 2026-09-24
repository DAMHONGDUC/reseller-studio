import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_status_card.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_app.dart';

/// **Every string a 1- or 2-line card commits to must actually fit.**
/// `maxLines` plus `overflow: ellipsis` stops a layout breaking, but it does
/// not stop a seller reading a sentence cut off mid-word — that is a content
/// bug, not a layout one, and it only shows up once translated, on the phone
/// width the card was written for. This pumps `AppStatusCard` itself — the
/// widget both the sync card and the guest banner share — with every
/// shipping locale's real copy, one case per test so a failure in one
/// locale never hides the next.
void main() {
  setUpAll(loadAppFonts);

  bool overflowed(WidgetTester tester, Finder finder) =>
      (tester.renderObject(finder) as RenderParagraph).didExceedMaxLines;

  Future<void> pumpCard(
    WidgetTester tester, {
    required String title,
    required String detail,
    required int detailMaxLines,
  }) => pumpScreen(
    tester,
    Scaffold(
      body: AppStatusCard(
        icon: AppIconConstant.cloudDone,
        tint: Colors.blue,
        title: title,
        detail: detail,
        detailMaxLines: detailMaxLines,
        onTap: () {},
      ),
    ),
  );

  for (final Locale locale in ResellerStudioApp.shippingLocales) {
    final AppLocalizations l10n = lookupAppLocalizations(locale);

    for (final (String caseName, String title, String detail)
        in <(String, String, String)>[
          ('checking', l10n.syncCheckingTitle, l10n.syncCheckingSubtitle),
          ('syncing', l10n.syncSyncingTitle, l10n.syncSyncingSubtitle),
          ('synced', l10n.syncSyncedTitle, l10n.syncSyncedSubtitle),
          (
            'device-only',
            l10n.syncDeviceOnlyTitle,
            l10n.syncDeviceOnlySubtitle,
          ),
        ]) {
      testWidgets(
        'sync card $caseName fits one line — ${locale.languageCode}',
        (WidgetTester tester) async {
          await pumpCard(
            tester,
            title: title,
            detail: detail,
            detailMaxLines: 1,
          );

          expect(
            overflowed(tester, find.text(title)),
            isFalse,
            reason: '${locale.languageCode} title: "$title"',
          );
          expect(
            overflowed(tester, find.text(detail)),
            isFalse,
            reason: '${locale.languageCode} detail: "$detail"',
          );
        },
      );
    }

    testWidgets('guest banner fits its two lines — ${locale.languageCode}', (
      WidgetTester tester,
    ) async {
      await pumpCard(
        tester,
        title: l10n.homeGuestBannerTitle,
        detail: l10n.homeGuestBannerSubtitle,
        detailMaxLines: 2,
      );

      expect(
        overflowed(tester, find.text(l10n.homeGuestBannerTitle)),
        isFalse,
        reason: '${locale.languageCode} title: "${l10n.homeGuestBannerTitle}"',
      );
      expect(
        overflowed(tester, find.text(l10n.homeGuestBannerSubtitle)),
        isFalse,
        reason:
            '${locale.languageCode} detail: '
            '"${l10n.homeGuestBannerSubtitle}"',
      );
    });
  }
}
