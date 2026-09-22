import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/firestore/firestore_mapper.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_json_codec.dart';
import 'package:reseller_studio/core/local/local_table.dart';

/// P1's gate: the guest store opens, holds a DTO's own map, and hands it back
/// in the order the Firestore repositories read in.
void main() {
  late LocalDatabase db;
  late LocalTable table;

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    table = LocalTable(db, db.localItems);
  });

  tearDown(() => db.close());

  test('a written record comes back with its map intact', () async {
    await table.put('a3f1', DateTime(2026, 9, 1), <String, Object?>{
      'title': 'Nike Air Max',
      'quantity': 2,
      'purchasePriceMinor': 1999,
      'workspaceId': 'local',
    });

    final LocalDocument? found = await table.findById('a3f1');

    expect(found, isNotNull);
    expect(found!.data['title'], 'Nike Air Max');
    expect(found.data['quantity'], 2);
    expect(found.data['purchasePriceMinor'], 1999);
  });

  test('a Firestore Timestamp survives the round trip as a readable date', () {
    final String encoded = LocalJsonCodec.encode(<String, Object?>{
      'purchaseDate': Timestamp.fromDate(DateTime.utc(2026, 3, 4)),
    });

    expect(
      FirestoreMapper.dateOrNull(LocalJsonCodec.decode(encoded)['purchaseDate']),
      DateTime.utc(2026, 3, 4).toLocal(),
    );
  });

  test('a serverTimestamp sentinel becomes the client clock', () {
    final DateTime now = DateTime.utc(2026, 9, 21, 14, 3);
    final String encoded = LocalJsonCodec.encode(<String, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
    }, now: now);

    expect(
      FirestoreMapper.dateOrNull(LocalJsonCodec.decode(encoded)['updatedAt']),
      now.toLocal(),
    );
  });

  test('records read back newest first', () async {
    await table.put('old', DateTime(2026), <String, Object?>{'title': 'old'});
    await table.put('new', DateTime(2026, 6), <String, Object?>{'title': 'new'});

    final List<LocalDocument> all = await table.getAll();

    expect(all.map((LocalDocument d) => d.id), <String>['new', 'old']);
  });

  test('a wipe empties every guest table', () async {
    await table.put('a3f1', DateTime(2026), <String, Object?>{'title': 'x'});

    await db.wipe();

    expect(await table.getAll(), isEmpty);
  });
}
