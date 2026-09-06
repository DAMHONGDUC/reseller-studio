/// The two platforms this app ships on.
///
/// **A domain enum rather than Flutter's `TargetPlatform`.** `app_config`
/// carries one update policy per store, and a store is what this names — the
/// `domain/` layer is pure Dart and cannot see Flutter's version, and the
/// desktop and web values it also carries are states this app does not have.
/// `currentPlatformProvider` is the one place the two meet.
enum AppPlatform { ios, android }
