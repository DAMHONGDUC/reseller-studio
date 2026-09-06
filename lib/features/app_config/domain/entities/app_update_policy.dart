/// What one store says about the build the seller is running.
///
/// **One per platform, because the two stores are never in step.** A build
/// number is only meaningful next to the store that issued it — `41` on the
/// App Store and `41` on Google Play are different binaries reviewed at
/// different times, so a single ceiling for both either stops a release that
/// shipped or lets an old one through.
class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.forceUpdateEnabled,
    required this.buildNumber,
    this.buildName,
    this.storeLink,
  });

  /// What a platform nobody has configured falls back to.
  ///
  /// **It forces nothing.** A wrong answer here locks every seller out of an
  /// app they cannot fix from their side, and there is no way to ship them out
  /// of it — where a missed prompt is one release cycle late.
  static const AppUpdatePolicy none = AppUpdatePolicy(
    forceUpdateEnabled: false,
    buildNumber: 0,
  );

  /// The master switch for this platform.
  ///
  /// **It is checked before [buildNumber], so raising the build alone forces
  /// nothing.** That is the point of having both: the owner keeps the numbers
  /// current as a matter of routine and turns the block on deliberately, once,
  /// when a build really cannot be left running.
  final bool forceUpdateEnabled;

  /// The build the store is on — the `+41` of `1.4.0+41`.
  ///
  /// **A build number, never a version string.** It is the monotonic integer
  /// the stores already order by, so the comparison is `<` and nothing else. A
  /// version string needs a comparator, and `1.10.0` against `1.9.0` is
  /// exactly where a hand-written one is wrong.
  final int buildNumber;

  /// The marketing version the seller recognises — `1.4.0`. Shown, never
  /// compared. Null leaves it out of the sheet rather than printing a blank.
  final String? buildName;

  /// Where the seller is sent to update. Null leaves the sheet without a
  /// button rather than sending them somewhere that does not exist.
  ///
  /// **Configured rather than compiled in**, because a broken store link must
  /// be fixable without shipping a release — which is the one thing a
  /// forced-update sheet cannot ask for.
  final String? storeLink;

  /// Whether [build] is too old to run.
  bool forcesUpdate(int build) => forceUpdateEnabled && build < buildNumber;

  Map<String, Object?> toLogData() => <String, Object?>{
    'forceUpdateEnabled': forceUpdateEnabled,
    'buildNumber': buildNumber,
    'buildName': buildName,
    'hasStoreLink': storeLink != null,
  };
}
