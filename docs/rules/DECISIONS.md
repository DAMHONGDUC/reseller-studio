# Decisions — the history behind the rules

Rationale that justifies a rule but is not itself actionable. Nothing here
needs to be in context to write correct code; it is here so the reasoning
survives, and so the rules it explains can stay short.

## Deep links hard-crash until Firebase is configured

Explains the `selleros://` deep-link entry under "Tech stack" in the root
`CLAUDE.md`.

  **Until Firebase is configured, any deep link hard-crashes the app**:
  `firebase_auth`'s iOS plugin intercepts `openURL` and constructs
  `Auth.auth()`, which fatals with *"The default FirebaseApp instance must be
  configured"*. It is a native crash, so `bootstrap`'s guarded zone cannot
  catch it. Nothing to fix in this app — it disappears the moment
  `flutterfire configure` has run. Don't spend an afternoon on it.

## The app bar stays opaque

Explains the opaque-app-bar rule in `DESIGN_SYSTEM.md`.

The app bar deliberately stays opaque: a blur there costs a shader pass on
every scroll frame of a list that can run to thousands of rows, whereas the
tab bar is a fixed strip whose cost does not grow with the content.

## Seller OS pays for v2's dependencies, and one of them warns on every Android build

Explains why the `Compiled to invalid SkSL` warning is not to be fixed.
Referenced from `DESIGN_SYSTEM.md`.

The package declares `liquid_glass_renderer`, `fl_chart` and `auto_size_text`
for the whole package, not per generation, so this app resolves them even
though **no file under `lib/` imports liquid glass** — it belongs to v2's
frosted chrome, which v3 deliberately does not have.

The visible cost: `flutter build apk` prints
`Compiled to invalid SkSL` for `liquid_glass_geometry_blended.frag`. **It is
non-fatal — the APK builds** — and it is not a bug in this app. Do not try to
fix it by editing the package's `pubspec.yaml` to drop the dependency; that
breaks BaroEase, which actually renders those widgets.

The real fix, if the noise ever justifies it, is splitting the package's
dependencies per generation, which pub does not support in one package —
meaning it would take a second package. Not worth it for a warning. Revisit
only if it becomes a build failure.
