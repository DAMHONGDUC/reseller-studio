import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **One glyph control, drawn one way** — owner's rules, in
/// `docs/rules/DESIGN_SYSTEM.md`.
///
/// The end glyph is `AppRowChevron` and an app bar action is
/// `SdAppBarActionButtonV3`; nothing draws either inline. Both rules exist
/// because the same control had grown three sizes and two greys across screens
/// a seller moves between all day, and every one of those looked right in the
/// file it was written in.
///
/// **Source rather than a pumped tree**, the way `row_affordance_test.dart`
/// does: the rule is about every call site in the app, and pumping the screens
/// that happen to have tests would check a fraction of them and call it all.
void main() {
  /// Every `.dart` file under `lib/`, as (path, source).
  List<({String path, String source})> sources() {
    final List<({String path, String source})> found =
        <({String path, String source})>[];

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      found.add((path: entity.path, source: entity.readAsStringSync()));
    }

    return found;
  }

  test('every lib file is read, or these tests prove nothing', () {
    expect(sources().length, greaterThan(100));
  });

  test('nothing draws the end chevron inline', () {
    // `AppRowChevron` owns the glyph, its size and its colour. Five call sites
    // had grown their own — three at `smallSize` in `textTertiary`, one a raw
    // `Icon` at Material's default — so scrolling Home met three sizes of the
    // same promise.
    const String owner = 'app_row_chevron.dart';
    final List<String> offenders = <String>[];

    for (final ({String path, String source}) file in sources()) {
      if (file.path.endsWith(owner)) continue;
      if (file.source.contains('AppIconConstant.chevronRight')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files draw their own chevron — use `AppRowChevron`, which '
          'owns the glyph, its size and its colour:\n${offenders.join('\n')}',
    );
  });

  test('no screen builds its own IconButton', () {
    // The two that may: the shared row control, and the camera overlay, which
    // carries its own circular surface because it has to read over a video
    // feed rather than over the page.
    const List<String> allowed = <String>[
      'app_row_icon_button.dart',
      'barcode_camera_view.dart',
    ];
    // Word-boundary, or `AppRowIconButton(` matches its own rule.
    final RegExp bare = RegExp(r'(?<![A-Za-z])IconButton\(');
    final List<String> offenders = <String>[];

    for (final ({String path, String source}) file in sources()) {
      if (allowed.any(file.path.endsWith)) continue;
      if (bare.hasMatch(file.source)) offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files hand-roll an icon control — an app bar action is '
          '`SdAppBarActionButtonV3` and a row action is `AppRowIconButton`, '
          'and both own their size and target:\n${offenders.join('\n')}',
    );
  });

  test('no widget falls back to a raw Material Icon', () {
    // `SdIconV3` is the one icon widget in v3: a bare `Icon` inherits from the
    // ambient `IconTheme`, so the same glyph comes out at a different size
    // depending on what happened to wrap it.
    final RegExp rawIcon = RegExp(r'(?<![A-Za-z])Icon\(');
    final List<String> offenders = <String>[];

    for (final ({String path, String source}) file in sources()) {
      if (rawIcon.hasMatch(file.source)) offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files build a raw `Icon` — use `SdIconV3`, which always '
          'resolves to a concrete size and colour:\n${offenders.join('\n')}',
    );
  });
}
