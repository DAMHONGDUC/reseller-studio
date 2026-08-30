import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Melos command uses a script from system_design', () {
    final String melos = File('melos.yaml').readAsStringSync();
    final Iterable<RegExpMatch> commands = RegExp(
      r'^\s+run: sh ([^\s]+)',
      multiLine: true,
    ).allMatches(melos);

    expect(commands, hasLength(13));

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

  test('release sets up and installs config before it deploys', () {
    final String release = File(
      'packages/system_design/tool/release.sh',
    ).readAsStringSync();
    final int setUp = release.indexOf('sh "\$SCRIPT_DIR/set-up.sh"');
    final int prepareEnv = release.indexOf('sh "\$SCRIPT_DIR/prepare-env.sh"');
    final int deploy = release.indexOf('sh "\$SCRIPT_DIR/deploy-firebase.sh"');

    expect(setUp, greaterThanOrEqualTo(0));
    expect(prepareEnv, greaterThan(setUp));
    expect(deploy, greaterThan(prepareEnv));

    // `pre-build` is among them: a gate full of this app's bundle ids and
    // entitlements cannot live in a folder every app embedding the design
    // system shares.
    for (final String name in <String>[
      'run',
      'test-rules',
      '_url-scheme',
      'pre-build',
    ]) {
      expect(
        File('packages/system_design/tool/$name.sh').existsSync(),
        isFalse,
      );
    }
  });

  test('pre-build is the app-owned fastlane lane', () {
    final String melos = File('melos.yaml').readAsStringSync();
    final String fastfile = File('ios/fastlane/Fastfile').readAsStringSync();

    expect(melos, contains('run: cd ios && bundle exec fastlane pre_build'));
    expect(fastfile, contains('lane :pre_build'));
  });

  test('beta names an export plist only when it wrote one', () {
    final String fastfile = File('ios/fastlane/Fastfile').readAsStringSync();

    // An empty `--export-options-plist=` counts as given to build-ipa.sh, so
    // it drops its own `--export-method` and the export dies on a path of "".
    expect(
      fastfile,
      contains(
        'build_args << "--export-options-plist=#{export_options}".shellescape '
        'if export_options',
      ),
    );
    expect(fastfile, isNot(contains('export_flag')));
  });
}
