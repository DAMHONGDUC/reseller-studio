import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hard rule 6, checked against the source rather than trusted.
///
/// **Every public method in a `data/` repository funnels through one of the
/// sanctioned boundaries** — `FailureMapper.guard` for a future, and
/// `FirestoreStream` (or an explicit `handleError`) for a stream, because a
/// snapshot listener fails long after the call that opened it returned. Past
/// that line `FirebaseException` does not exist, which is what lets `domain/`
/// and `presentation/` be written as if it never did.
///
/// A test rather than a review note: the rule is invisible at the call site,
/// and one method added without it is one raw platform message reaching a
/// seller.
void main() {
  /// What counts as having mapped a failure.
  const List<String> boundaries = <String>[
    'FailureMapper.guard',
    'FailureMapper.map',
    'FirestoreStream.',
    '.handleError',
  ];

  /// Repositories that deliberately cannot fail, with the reason.
  ///
  /// Both are the "there is no backend" stand-ins: they answer from a
  /// constant and never call out, so there is nothing to map.
  const List<String> constantRepositories = <String>[
    'fallback_app_config_repository.dart',
    'unconfigured_subscription_repository.dart',
  ];

  /// The one stream that degrades instead of mapping, and why.
  ///
  /// `watchStatus` feeds a controller that only ever receives a value: a
  /// billing SDK that cannot answer logs and emits Free, so no error reaches
  /// the stream at all. Mapping one would put a red screen in front of a
  /// seller over an entitlement read.
  const Map<String, String> degradesInstead = <String, String>{
    'revenue_cat_subscription_repository.dart': 'watchStatus',
  };

  /// The body of every `Future`/`Stream` method in [source], by name.
  ///
  /// Both forms: an arrow body runs to its `;` at depth zero, a block body to
  /// its matching brace.
  Map<String, String> bodiesIn(String source) {
    final Map<String, String> bodies = <String, String>{};
    final RegExp signature = RegExp(
      r'^  ((?:Future|Stream)<[^;{]*?)\s+(\w+)\(',
      multiLine: true,
    );

    for (final RegExpMatch match in signature.allMatches(source)) {
      int index = match.end - 1;
      int depth = 0;

      while (index < source.length) {
        final String character = source[index];

        if ('([{<'.contains(character)) depth++;
        if (')]}>'.contains(character)) {
          depth--;
          if (depth == 0) break;
        }
        index++;
      }

      int cursor = index + 1;

      while (cursor < source.length && !'{=;'.contains(source[cursor])) {
        cursor++;
      }

      if (source.startsWith('{', cursor)) {
        int end = cursor;
        int braces = 0;

        while (end < source.length) {
          if (source[end] == '{') braces++;
          if (source[end] == '}') {
            braces--;
            if (braces == 0) break;
          }
          end++;
        }

        bodies[match.group(2)!] = source.substring(cursor, end + 1);
      } else if (source.startsWith('=>', cursor)) {
        int end = cursor;
        int open = 0;

        while (end < source.length) {
          final String character = source[end];

          if ('([{'.contains(character)) open++;
          if (')]}'.contains(character)) open--;
          if (character == ';' && open == 0) break;
          end++;
        }

        bodies[match.group(2)!] = source.substring(cursor, end + 1);
      }
    }

    return bodies;
  }

  /// True when [body] maps its failures, directly or through a private
  /// helper in the same file that does.
  bool mapsFailures(
    String body,
    Map<String, String> bodies, [
    Set<String> seen = const <String>{},
  ]) {
    for (final String boundary in boundaries) {
      if (body.contains(boundary)) return true;
    }

    for (final RegExpMatch call in RegExp(r'\b(_\w+)\(').allMatches(body)) {
      final String helper = call.group(1)!;

      if (seen.contains(helper) || !bodies.containsKey(helper)) continue;
      if (mapsFailures(bodies[helper]!, bodies, <String>{...seen, helper})) {
        return true;
      }
    }

    return false;
  }

  test('every data repository method maps its failures', () {
    final List<File> repositories =
        Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (File file) =>
                  file.path.contains('/data/repositories/') &&
                  file.path.endsWith('.dart'),
            )
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    final List<String> unguarded = <String>[];

    // The scan is worthless if it stops finding the files.
    expect(repositories.length, greaterThan(15));

    for (final File repository in repositories) {
      if (constantRepositories.any(repository.path.endsWith)) continue;

      final Map<String, String> bodies = bodiesIn(
        repository.readAsStringSync(),
      );

      bodies.forEach((String name, String body) {
        if (name.startsWith('_') || body.trim().isEmpty) return;
        if (mapsFailures(body, bodies)) return;
        if (degradesInstead.entries.any(
          (MapEntry<String, String> allowed) =>
              repository.path.endsWith(allowed.key) && name == allowed.value,
        )) {
          return;
        }

        unguarded.add('${repository.path}: $name');
      });
    }

    expect(
      unguarded,
      isEmpty,
      reason:
          'these reach presentation with whatever the SDK threw — wrap the '
          'future in FailureMapper.guard, or open the stream through '
          'FirestoreStream',
    );
  });
}
