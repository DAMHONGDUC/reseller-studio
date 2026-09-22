import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Turns a Firestore DTO map into something SQLite can hold, and back.
///
/// **The local store keeps the DTO's own map, not a second shape**
/// (`docs/rules/GUEST_MODE.md`). Two things in that map are not JSON:
/// `Timestamp`, and the `FieldValue` sentinel a DTO writes into `updatedAt`.
/// Both become ISO strings — and nothing has to be written to read them back,
/// because `FirestoreMapper.dateOrNull` already accepts an ISO string
/// alongside a `Timestamp`. That is the whole reason the drain is a copy.
///
/// **A `FieldValue` becomes the client clock**, which is the one place this
/// app does not get a server timestamp. It cannot: there is no server. The
/// drain rewrites `updatedAt` as a real server timestamp on the way up, so
/// the client value never outlives the push.
final class LocalJsonCodec {
  static String encode(Map<String, Object?> data, {DateTime? now}) =>
      jsonEncode(_jsonSafe(data, now ?? DateTime.now()));

  static Map<String, Object?> decode(String raw) {
    final Object? decoded = jsonDecode(raw);

    if (decoded is Map<String, Object?>) return decoded;

    return <String, Object?>{};
  }

  /// **Always UTC.** `Timestamp.toDate()` hands back a local `DateTime`,
  /// whose ISO form carries no zone — so the same instant read back on a
  /// phone that has since crossed a timezone would be a different one.
  static String _iso(DateTime value) => value.toUtc().toIso8601String();

  static Object? _jsonSafe(Object? value, DateTime now) {
    if (value is Timestamp) return _iso(value.toDate());
    if (value is DateTime) return _iso(value);
    // The only `FieldValue` any DTO writes is `serverTimestamp`, and there is
    // no way to ask an instance which one it is — so the substitution is the
    // clock, for every one of them.
    if (value is FieldValue) return _iso(now);

    if (value is Map) {
      return <String, Object?>{
        for (final MapEntry<Object?, Object?> entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value, now),
      };
    }

    if (value is Iterable) {
      return <Object?>[
        for (final Object? element in value) _jsonSafe(element, now),
      ];
    }

    return value;
  }
}
