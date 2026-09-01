import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/theme/app_tag_hue.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/marketplace_constant.dart';

/// **A marketplace's colour survives a round trip and never throws.**
///
/// The two ways this breaks are both silent: a hue stored by index would
/// repaint every marketplace the moment the enum is reordered, and a hue name
/// a later build wrote would take out the row that reads it.
void main() {
  test('an unknown or missing stored hue falls back to grey', () {
    expect(AppTagHue.fromName(null), AppTagHue.grey);
    expect(AppTagHue.fromName(''), AppTagHue.grey);
    expect(AppTagHue.fromName('chartreuse'), AppTagHue.grey);
  });

  test('every hue round-trips through its stored name', () {
    for (final AppTagHue hue in AppTagHue.values) {
      expect(AppTagHue.fromName(hue.name), hue);
    }
  });

  test('a marketplace with no colour opinion is grey', () {
    final Marketplace marketplace = Marketplace(
      id: 'm-1',
      name: 'Car boot',
      feeRate: 0,
      createdAt: DateTime(2026),
    );

    expect(marketplace.hue, AppTagHue.grey);
    expect(marketplace.copyWith(hue: AppTagHue.teal).hue, AppTagHue.teal);
  });

  test('the seeded marketplaces each start on a different hue', () {
    final Set<AppTagHue> hues = MarketplaceConstant.defaults
        .map((MarketplaceSeed seed) => seed.hue)
        .toSet();

    expect(hues.length, MarketplaceConstant.defaults.length);
    expect(hues, isNot(contains(AppTagHue.grey)));
  });
}
