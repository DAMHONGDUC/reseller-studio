import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/scan_match.dart';
import 'package:reseller_studio/features/inventory/domain/services/scan_lookup.dart';

import '../../support/barcode_label_decoder.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/fixtures/sample_bottles.dart';
import '../../support/pump_app.dart';

/// The sample bottles: their labels carry the codes the fixture says, and
/// each code lands on the record a seller holding that bottle expects.
void main() {
  final MockDataset dataset = MockDataset.seed(now: testNow);
  final List<Item> items = <Item>[
    ...dataset.items,
    ...SampleBottles.items(now: testNow),
  ];

  ScanMatch scan(String code) =>
      ScanLookup.resolve(code, items: items, locations: dataset.locations);

  group('labels', () {
    for (final SampleBottle bottle in SampleBottles.all) {
      test('${bottle.slug} decodes to its code', () {
        final String decoded = BarcodeLabelDecoder.decodeSvg(bottle.svgPath);

        // A UPC-A is drawn as the EAN-13 it is, leading zero and all.
        expect(
          decoded,
          bottle.code.length == 12 ? '0${bottle.code}' : bottle.code,
        );
      });
    }
  });

  group('lookup', () {
    for (final SampleBottle bottle in SampleBottles.all.where(
      (SampleBottle bottle) => bottle.itemId != null,
    )) {
      test('${bottle.slug} finds its item', () {
        final ScanMatch match = scan(bottle.code);

        expect(match, isA<ScanMatchItem>());
        expect((match as ScanMatchItem).item.id, bottle.itemId);
      });
    }

    test('a UPC-A is found as iOS reads it, with a leading zero', () {
      final ScanMatch match = scan('0${SampleBottles.flask.code}');

      expect((match as ScanMatchItem).item.id, SampleBottles.flask.itemId);
    });

    test('an item stored as thirteen digits is found from twelve', () {
      final ScanMatch match = ScanLookup.resolve(
        SampleBottles.flask.code,
        items: <Item>[
          SampleBottles.items(
            now: testNow,
          )[1].copyWith(barcode: '0${SampleBottles.flask.code}'),
        ],
        locations: dataset.locations,
      );

      expect(match, isA<ScanMatchItem>());
    });

    test('the bottle nobody owns matches nothing', () {
      expect(scan(SampleBottles.water.code), isA<ScanMatchNone>());
    });

    test('a SKU finds its bottle too', () {
      expect(scan('BTL-0003'), isA<ScanMatchItem>());
    });

    test('a bin label lists what is on it, the flask included', () {
      final ScanMatch match = scan('BIN-A1');

      expect(match, isA<ScanMatchLocation>());
      expect(
        (match as ScanMatchLocation).items.map((Item item) => item.id),
        contains(SampleBottles.flask.itemId),
      );
    });

    test('a deleted bottle is not found', () {
      final ScanMatch match = ScanLookup.resolve(
        SampleBottles.perfume.code,
        items: <Item>[
          SampleBottles.items(now: testNow).first.copyWith(deletedAt: testNow),
        ],
        locations: dataset.locations,
      );

      expect(match, isA<ScanMatchNone>());
    });

    test('a blank read matches nothing, not a record with no barcode', () {
      expect(scan('  '), isA<ScanMatchNone>());
    });
  });
}
