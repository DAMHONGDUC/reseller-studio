import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Melos command uses a script from system_design', () {
    final String melos = File('melos.yaml').readAsStringSync();
    final Iterable<RegExpMatch> commands = RegExp(
      r'^\s+run: sh ([^\s]+)',
      multiLine: true,
    ).allMatches(melos);

    expect(commands, hasLength(14));

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

  test(
    'release runs preflight before deploy and removed scripts stay absent',
    () {
      final String release = File(
        'packages/system_design/tool/release.sh',
      ).readAsStringSync();
      final int preflight = release.indexOf('sh "\$SCRIPT_DIR/preflight.sh"');
      final int deploy = release.indexOf(
        'sh "\$SCRIPT_DIR/deploy-firebase.sh"',
      );

      expect(preflight, greaterThanOrEqualTo(0));
      expect(deploy, greaterThan(preflight));

      for (final String name in <String>['run', 'test-rules', '_url-scheme']) {
        expect(
          File('packages/system_design/tool/$name.sh').existsSync(),
          isFalse,
        );
      }
    },
  );
}
