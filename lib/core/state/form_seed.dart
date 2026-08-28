import 'package:flutter/widgets.dart';

/// Copies a record that arrived asynchronously into a form, exactly once and
/// never during a build.
///
/// **A form seeds from `build`, and a provider must not be written there.**
/// The record arrives on a stream, so the only place a screen learns it has
/// one is the build that receives it — and writing the form's controller from
/// there throws `Tried to modify a provider while the widget tree was
/// building`. Deferring to the end of the frame is the fix Riverpod's own
/// message names, and it costs one frame of empty fields on a screen that was
/// already showing empty fields while the record loaded.
///
/// **In `core/` because two screens do it** — the item form and the workspace
/// detail form — and both had written the same one-time flag and the same bug
/// beside it. What each screen keeps is the copying itself, which is the part
/// that knows the entity.
///
/// The "once" matters as much as the timing: the record rebuilds the screen
/// whenever a teammate edits it, and re-seeding then would throw away every
/// keystroke the seller had made in between.
mixin FormSeed<T extends StatefulWidget> on State<T> {
  bool _seeded = false;

  /// Whether [seedOnce] has already been given its record.
  bool get isSeeded => _seeded;

  /// Runs [seed] after the current frame, and only for the first call.
  ///
  /// The flag is set synchronously, so a second build in the same frame does
  /// not schedule a second copy.
  void seedOnce(VoidCallback seed) {
    if (_seeded) return;

    _seeded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The seller may have popped the screen inside that frame.
      if (!mounted) return;

      seed();
    });
  }
}
