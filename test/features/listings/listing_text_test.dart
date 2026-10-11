import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/listings/domain/entities/title_parts.dart';
import 'package:reseller_studio/features/listings/domain/services/supplier_text_cleaner.dart';
import 'package:reseller_studio/features/listings/domain/services/title_builder.dart';

/// The title builder and the supplier text cleaner — the rule-based tools
/// that stand in for an AI rewrite (decision 11.9).
void main() {
  group('TitleBuilder', () {
    test('assembles the parts in order', () {
      expect(
        TitleBuilder.build(
          const TitleParts(
            brand: 'Nike',
            productType: 'Running Shoes',
            attributes: <String>['Pegasus 40', 'Mesh'],
            color: 'Black',
            size: 'UK 9',
            condition: 'New with box',
          ),
          maxLength: 80,
        ),
        'Nike Running Shoes Pegasus 40 Mesh Black UK 9 New with box',
      );
    });

    test('does not repeat a word, whatever its case', () {
      expect(
        TitleBuilder.build(
          const TitleParts(brand: 'Nike', productType: 'nike Trainers'),
          maxLength: 80,
        ),
        'Nike Trainers',
      );
    });

    test('drops the last attribute, then colour, then condition', () {
      const TitleParts parts = TitleParts(
        brand: 'Levis',
        productType: 'Jacket',
        attributes: <String>['Trucker', 'Denim'],
        color: 'Blue',
        size: 'M',
        condition: 'Used',
      );

      expect(
        TitleBuilder.build(parts, maxLength: 35),
        'Levis Jacket Trucker Blue M Used',
      );
      expect(
        TitleBuilder.build(parts, maxLength: 28),
        'Levis Jacket Blue M Used',
      );
      expect(TitleBuilder.build(parts, maxLength: 18), 'Levis Jacket M');
    });

    test('cuts the kept parts at a word, never mid-word', () {
      expect(
        TitleBuilder.build(
          const TitleParts(productType: 'Extraordinarily long product name'),
          maxLength: 18,
        ),
        'Extraordinarily',
      );
    });

    test('knows the platform limits and falls back to eBay', () {
      expect(TitleBuilder.maxLengthFor('etsy'), 140);
      expect(TitleBuilder.maxLengthFor('my-own-shop'), 80);
    });
  });

  group('SupplierTextCleaner.cleanTitle', () {
    test('strips filler, hype years, emoji and brackets', () {
      expect(
        SupplierTextCleaner.cleanTitle(
          '【2026 New】🔥 Hot Sale Women Summer Dress Free Shipping ✨',
        ),
        'Women Summer Dress',
      );
    });

    test('removes repeated words', () {
      expect(
        SupplierTextCleaner.cleanTitle('Dress Women Dress Summer women'),
        'Dress Women Summer',
      );
    });

    test('turns an all-capitals title into title case', () {
      expect(
        SupplierTextCleaner.cleanTitle('LEATHER WALLET FOR MEN'),
        'Leather Wallet For Men',
      );
    });

    test('leaves a clean title alone', () {
      expect(
        SupplierTextCleaner.cleanTitle('Leather Wallet for Men'),
        'Leather Wallet for Men',
      );
    });
  });

  group('SupplierTextCleaner.cleanDescription', () {
    test('turns markup into plain lines and drops reseller-only lines', () {
      expect(
        SupplierTextCleaner.cleanDescription(
          '<p>Soft cotton &amp; linen.</p><br>Wholesale and dropship welcome!'
          '<br><br><br><br>Machine washable 😊',
        ),
        'Soft cotton & linen.\n\nMachine washable',
      );
    });

    test('removes filler inside a line and keeps the rest', () {
      expect(
        SupplierTextCleaner.cleanDescription('High quality steel. In stock.'),
        'Steel.',
      );
    });
  });
}
