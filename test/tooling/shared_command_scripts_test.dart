import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Melos command uses a script from system_design', () {
    final String melos = File('melos.yaml').readAsStringSync();
    final Iterable<RegExpMatch> commands = RegExp(
      r'^\s+run: sh ([^\s]+)',
      multiLine: true,
    ).allMatches(melos);

    expect(commands, hasLength(16));

    for (final RegExpMatch command in commands) {
      final String path = command.group(1)!;

      expect(path, startsWith('packages/system_design/tool/'));
      expect(File(path).existsSync(), isTrue, reason: '$path must exist');
    }

    final Directory localTool = Directory('tool');
    final Iterable<FileSystemEntity> localScripts = localTool.existsSync()
        ? localTool.listSync().where(
            (FileSystemEntity file) =>
                file is File && file.path.endsWith('.sh'),
          )
        : const <FileSystemEntity>[];

    expect(localScripts, isEmpty);
  });
}
