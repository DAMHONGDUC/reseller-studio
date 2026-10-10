import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String scripts = 'packages/script-tools/flutter';

  test('every command is a make target from the shared script-tools', () {
    final String makefile = File('Makefile').readAsStringSync();
    final Directory localTool = Directory('tool');
    final Iterable<FileSystemEntity> localScripts = localTool.existsSync()
        ? localTool.listSync().where(
            (FileSystemEntity file) =>
                file is File && file.path.endsWith('.sh'),
          )
        : const <FileSystemEntity>[];

    expect(makefile, contains('SCRIPT_TOOLS := packages/script-tools'));
    expect(makefile, contains(r'include $(SCRIPT_TOOLS)/flutter/flutter.mk'));
    expect(File('$scripts/flutter.mk').existsSync(), isTrue);
    expect(File('melos.yaml').existsSync(), isFalse);
    expect(localScripts, isEmpty);
  });

  test('release installs config before it deploys, and never sets up', () {
    final String release = File('$scripts/release_ios.sh').readAsStringSync();
    final int prepareEnv = release.indexOf(
      'bash "\$FLUTTER_TOOLS_DIR/prepare_env.sh"',
    );
    final int deploy = release.indexOf(
      'bash "\$FLUTTER_TOOLS_DIR/deploy_firebase.sh"',
    );

    // A release builds the tree as it stands — owner's rule. A tree that needs
    // restoring is restored by `make set-up` first, on purpose.
    expect(release, isNot(contains('bash "\$FLUTTER_TOOLS_DIR/set_up.sh"')));
    expect(prepareEnv, greaterThanOrEqualTo(0));
    expect(deploy, greaterThan(prepareEnv));
  });

  test('the preflight gate is a shared fastlane lane make calls', () {
    final String makefile = File('Makefile').readAsStringSync();
    final String app = File('ios/fastlane/Fastfile').readAsStringSync();
    final String shared = File('$scripts/fastlane/Fastfile').readAsStringSync();

    expect(makefile, contains('bundle exec fastlane preflight'));
    expect(shared, contains('lane :preflight'));

    // A lane copied here is one that stops getting the next fix — the app
    // Fastfile imports the pipeline and declares only what it is aiming at.
    expect(app, contains('import "../../$scripts/fastlane/Fastfile"'));
    expect(app, isNot(contains('lane :')));
  });

  test('beta names an export plist only when it wrote one', () {
    final String fastfile = File(
      '$scripts/fastlane/Fastfile',
    ).readAsStringSync();

    // An empty `--export-options-plist=` counts as given to build_ipa.sh, so
    // it drops its own `--export-method` and the export dies on a path of "".
    expect(
      fastfile,
      contains(
        'command << "--export-options-plist=#{export_plist}" if export_plist',
      ),
    );
    expect(fastfile, isNot(contains('export_flag')));
  });

  test('firebase deploy checks project access before it sends anything', () {
    final String deploy = File(
      '$scripts/deploy_firebase.sh',
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
    final String build = File('$scripts/build_ipa.sh').readAsStringSync();
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

  test('nothing reaches fastlane without a UTF-8 locale', () {
    final String makefile = File('Makefile').readAsStringSync();
    final String common = File('$scripts/lib/common.sh').readAsStringSync();
    final int guard = makefile.indexOf('LANG=en_US.UTF-8');
    final int lane = makefile.indexOf('bundle exec fastlane preflight');

    // Ruby fixes `Encoding.default_external` at startup, and fastlane reads
    // the shared Fastfile with it — so under `LANG=C` the lane dies on the
    // first em dash, with syntax errors naming lines that are fine.
    expect(common, contains('ensure_utf8_locale()'));

    for (final String script in <String>['release_ios.sh', 'upload_ipa.sh']) {
      expect(
        File('$scripts/$script').readAsStringSync(),
        contains('ensure_utf8_locale'),
        reason: '$script hands a lane whatever locale the caller had',
      );
    }

    // The app's pre-build target runs the lane directly, so it carries its own guard.
    expect(guard, greaterThanOrEqualTo(0));
    expect(lane, greaterThan(guard));
  });
}
