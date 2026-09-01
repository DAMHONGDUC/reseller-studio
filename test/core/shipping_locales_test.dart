import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

/// What a build offers a device, which is not what the ARB folder contains.
///
/// `app_vi.arb` is a partial file and the generator fills its gaps from
/// English, so a Vietnamese device would get a mixed-language app out of
/// translations hard rule 7 calls unreviewed. The list is English until the
/// one translation pass at release.
void main() {
  test('only English ships', () {
    expect(
      ResellerStudioApp.shippingLocales,
      const <Locale>[Locale('en')],
    );
  });

  test('the generated list still carries vi, so nothing deleted the keys', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('vi')));
  });
}
