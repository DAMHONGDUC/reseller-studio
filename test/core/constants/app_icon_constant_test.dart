import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';

void main() {
  test('semantic icons resolve through the app registry', () {
    expect(AppIconConstant.add, Symbols.add_rounded);
    expect(AppIconConstant.delete, Icons.delete_outline_rounded);
  });

  test('no library file chooses a glyph outside the registry', () {
    const String registryPath = 'lib/core/constants/app_icon_constant.dart';
    final RegExp directGlyph = RegExp(r'\b(?:Icons|Symbols)\.');
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File ||
          !entity.path.endsWith('.dart') ||
          entity.path == registryPath) {
        continue;
      }

      if (directGlyph.hasMatch(entity.readAsStringSync())) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });
}
