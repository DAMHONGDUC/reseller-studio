import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Every query a repository writes has an index declared for it.**
///
/// `firestore.indexes.json` is the index authority and `docs/rules/BACKEND.md`
/// says an index is added in the same change as the query needing it — but
/// nothing enforced that, and every base list query in the app shipped without
/// one. The whole app came up empty against a real project, five collections
/// at a time, and the only symptom was a `failed-precondition` in the console.
///
/// So this reads the repositories rather than a hand-kept list: a query added
/// tomorrow fails here rather than in front of a seller.
void main() {
  test('every workspace query has a composite index declared', () {
    final Set<String> declared = _declaredIndexes();
    final List<_Query> queries = _repositoryQueries();
    final List<String> missing = <String>[];

    expect(
      queries,
      isNotEmpty,
      reason: 'the scanner found no queries, so it has stopped matching',
    );

    for (final _Query query in queries) {
      if (!declared.contains(query.signature)) missing.add(query.signature);
    }

    expect(missing, isEmpty, reason: 'add these to firestore.indexes.json');
  });
}

/// Every declared index, and every prefix of one.
///
/// Firestore serves a query from any index the query is a prefix of, so
/// `(workspaceId, status, createdAt)` already covers `(workspaceId, status)`.
Set<String> _declaredIndexes() {
  final Map<String, Object?> json =
      jsonDecode(File('firestore.indexes.json').readAsStringSync())
          as Map<String, Object?>;
  final List<Object?> indexes = json['indexes']! as List<Object?>;
  final Set<String> signatures = <String>{};

  for (final Object? entry in indexes) {
    final Map<String, Object?> index = entry! as Map<String, Object?>;
    final String group = index['collectionGroup']! as String;
    final List<Object?> fields = index['fields']! as List<Object?>;
    final List<String> parts = <String>[];

    for (final Object? raw in fields) {
      final Map<String, Object?> field = raw! as Map<String, Object?>;

      parts.add('${field['fieldPath']}:${field['order']}');
      signatures.add('$group|${parts.join(',')}');
    }
  }

  return signatures;
}

/// The `.query…` chains in `lib/features/*/data/repositories/`.
///
/// A regex over Dart rather than a parse, which is fine because the shape is
/// uniform in this repo — `WorkspaceTable.query` is the only way to a
/// collection. If that changes, the emptiness check above fails loudly rather
/// than the scan quietly matching nothing.
List<_Query> _repositoryQueries() {
  final RegExp chain = RegExp(r'collections\.(\w+)\.query([^;]*?)\s*,\s*\n');
  final RegExp where = RegExp(r"\.where\(\s*'(\w+)'\s*,\s*isEqualTo:");
  final RegExp orderBy = RegExp(
    r"\.orderBy\(\s*'(\w+)'\s*(,\s*descending:\s*(true|false)\s*,?)?\s*\)",
  );
  final List<_Query> queries = <_Query>[];

  for (final FileSystemEntity entity in Directory(
    'lib/features',
  ).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (!entity.path.contains('/data/repositories/')) continue;

    for (final RegExpMatch match in chain.allMatches(
      entity.readAsStringSync(),
    )) {
      final String table = match.group(1)!;
      final String rest = match.group(2)!;
      final List<String> fields = <String>['workspaceId:ASCENDING'];

      for (final RegExpMatch equality in where.allMatches(rest)) {
        fields.add('${equality.group(1)}:ASCENDING');
      }
      for (final RegExpMatch sort in orderBy.allMatches(rest)) {
        final bool descending = sort.group(3) == 'true';

        fields.add(
          '${sort.group(1)}:${descending ? 'DESCENDING' : 'ASCENDING'}',
        );
      }

      // One field is the workspace filter alone, which needs no composite
      // index — the single-field index Firestore keeps automatically serves it.
      if (fields.length > 1) queries.add(_Query(table, fields.join(',')));
    }
  }

  return queries;
}

class _Query {
  const _Query(this.table, this.fields);

  final String table;
  final String fields;

  String get signature => '$table|$fields';
}
