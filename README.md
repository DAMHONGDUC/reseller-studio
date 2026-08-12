# Seller OS

A seller operating system for resellers — not an inventory tracker.

```text
SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE → SOURCE BETTER
```

Flutter · Firebase · Riverpod · design system v3.

## Getting started

Requires [fvm](https://fvm.app) and Melos 6.3.3:

```sh
dart pub global activate melos 6.3.3
fvm install                 # installs Flutter 3.44.5, per .fvmrc
melos run set-up            # submodules, deps, l10n, functions, pods
```

Then, before the app can reach a backend, run `flutterfire configure` — there
is no Firebase project checked in and none can be. See **Pending setup** in
`CLAUDE.md`.

`melos run analyze` must pass with zero findings before any change is done.

## Where things are

| | |
| --- | --- |
| Product spec, the authority | `SELLER_OS_FINAL_MASTER_PLAN.md` |
| Engineering rules | `CLAUDE.md` |
| Firestore collections and field contracts | `docs/DATA_MODEL.md` |
| What may go in the design system | `packages/system_design/WIDGET_RULES.md` |

## The design system is a submodule

`packages/system_design` is [its own repo](https://github.com/DAMHONGDUC/system_design),
shared with BaroEase. It carries two widget generations: `v2/` renders
BaroEase, `v3/` renders Seller OS. **Never modify `v2/`, and never import it
from `v3/`.**
