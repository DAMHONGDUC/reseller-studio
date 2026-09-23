import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../money/money.dart';

/// Reading Firestore field values into Dart types, and back.
///
/// **Every read is defensive.** A document is written by whatever version of
/// the app was installed when it was created, and a field that came back the
/// wrong shape must not take a screen down — hard rule 6 says the seller sees
/// a working list, not a `TypeError`. So every getter here takes `Object?`,
/// returns null on anything it does not recognise, and logs the shape it saw.
///
/// The money side is hard rule 4 expressed as a boundary: Firestore stores an
/// integer of minor units with a sibling currency, and nothing on either side
/// of this class ever holds a `double`.
final class FirestoreMapper {
  /// What Firestore writes into `createdAt` / `updatedAt`.
  ///
  /// **Never a client clock** — a phone with a wrong date would otherwise
  /// sort itself to the top of every list forever (`docs/DATA_MODEL.md`).
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// A `Timestamp`, an ISO string, or null.
  ///
  /// Both shapes are accepted because a document written by a Cloud Function
  /// carries a `Timestamp` while one restored from an export can carry a
  /// string, and a seller should not lose a purchase date to that.
  static DateTime? dateOrNull(Object? value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);

      if (parsed == null) {
        SdLogger.warning(
          LogTagConstant.firestore,
          'Unparseable date field',
          <String, String>{'value': value},
        );
      }

      // **Local, to match `Timestamp.toDate()`.** An ISO string parses to UTC
      // when it carries a zone, and a date that rendered one way from
      // Firestore and another from the local store is a bug that only shows
      // up east of Greenwich.
      return parsed?.toLocal();
    }

    SdLogger.warning(
      LogTagConstant.firestore,
      'Unexpected date field type',
      <String, String>{'type': value.runtimeType.toString()},
    );

    return null;
  }

  /// A date that a document is not valid without — `createdAt`, `orderedAt`.
  ///
  /// [fallback] rather than a throw: a server timestamp reads back null for
  /// the instant between a local write and the server's acknowledgement, and
  /// a list that threw during that window would flicker into an error state
  /// on every create.
  static DateTime dateOr(Object? value, DateTime fallback) =>
      dateOrNull(value) ?? fallback;

  static int? intOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();

    return null;
  }

  static double? doubleOrNull(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return null;
  }

  static String? stringOrNull(Object? value) {
    if (value is! String) return null;

    return value.isEmpty ? null : value;
  }

  static bool boolOr(Object? value, {required bool fallback}) =>
      value is bool ? value : fallback;

  static List<String> stringList(Object? value) {
    if (value is! List) return const <String>[];

    return value.whereType<String>().toList();
  }

  /// An enum by name, or null when the stored value names no case.
  ///
  /// Null rather than a default, so a caller decides what an unknown status
  /// means for it. A silent default here is how an order written by a newer
  /// build shows up as `awaitingPayment` on an older one.
  static T? enumOrNull<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;

    for (final T value in values) {
      if (value.name == name) return value;
    }

    SdLogger.warning(
      LogTagConstant.firestore,
      'Unknown enum value in document',
      <String, String>{'value': name, 'type': T.toString()},
    );

    return null;
  }

  /// Minor units plus a currency, or null when the amount was never entered.
  ///
  /// **Null is "not known", never zero** (hard rule 4). An absent field means
  /// nobody typed a cost, and the app renders `—` for it rather than claiming
  /// the item was free.
  static Money? moneyOrNull(Object? minor, String currency) {
    final int? units = intOrNull(minor);

    if (units == null) return null;

    return Money(units, currency);
  }

  /// The stored form of an amount — its minor units, or null.
  static int? minorOrNull(Money? amount) => amount?.minor;

  /// Drop the nulls before writing.
  ///
  /// Firestore treats a written null as "set this field to null", which is
  /// indistinguishable from "clear it". Every write in this app is a full
  /// document merge, so a field the entity does not carry must simply not
  /// appear rather than arrive as an explicit null.
  static Map<String, Object?> pruned(Map<String, Object?> data) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in data.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }
}
