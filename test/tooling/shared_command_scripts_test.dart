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

  test('release installs config before it deploys, and never sets up', () {
    final String release = File(
      'packages/system_design/tool/release.sh',
    ).readAsStringSync();
    final int prepareEnv = release.indexOf('sh "\$SCRIPT_DIR/prepare-env.sh"');
    final int deploy = release.indexOf('sh "\$SCRIPT_DIR/deploy-firebase.sh"');

    // A release builds the tree as it stands — owner's rule. A tree that needs
    // restoring is restored by `melos run set-up` first, on purpose, rather
    // than paying a cold wipe-and-regenerate on every release.
    expect(release, isNot(contains('sh "\$SCRIPT_DIR/set-up.sh"')));
    expect(prepareEnv, greaterThanOrEqualTo(0));
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

  test('firebase deploy checks project access before it sends anything', () {
    final String deploy = File(
      'packages/system_design/tool/deploy-firebase.sh',
    ).readAsStringSync();
    final int accessCheck = deploy.indexOf('projects:list --json');
    final int firstDeploy = deploy.indexOf(r'"$FIREBASE" deploy');

    // The 403 this replaces names neither the account nor the project, and the
    // CLI keeps one login for every repo on the machine.
    expect(deploy, contains('login:list'));
    expect(accessCheck, greaterThanOrEqualTo(0));
    expect(firstDeploy, greaterThan(accessCheck));

    // CI signs in as a service account that often cannot enumerate projects at
    // all — a list that fails is skipped, never read as a missing project.
    expect(deploy, contains('access was not checked'));
  });

  test('the archive resolves swift packages before flutter builds', () {
    final String build = File(
      'packages/system_design/tool/build-ipa.sh',
    ).readAsStringSync();
    final int resolve = build.indexOf('-resolvePackageDependencies');
    final int buildIpa = build.indexOf(r'$FL build ipa');

    // flutter runs its own resolve without -skipPackageUpdates and drops that
    // step's stdout, so an unreachable github dies with the reason cut off.
    expect(resolve, greaterThanOrEqualTo(0));
    expect(buildIpa, greaterThan(resolve));

    // Warming any other directory would leave flutter's resolve fetching anyway.
    expect(build, contains('-clonedSourcePackagesDirPath'));

    // The probe this replaced answered a different question: an HTTP GET to
    // github.com succeeded while the git fetch behind SPM timed out on 443.
    expect(build, isNot(contains('curl')));
  });
}
