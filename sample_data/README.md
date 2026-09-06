# Sample data

One file per Firestore document, holding what that document looks like with
every field filled in. The path mirrors the collection:
`sample_data/<collection>/<documentId>.json`.

**It is a reference, not a fixture.** Nothing reads these files — not the app,
not a test, not a seeding script. They exist so a document that is created by
hand in the Firebase console can be copied rather than remembered, and so the
shape of one is reviewable in a diff.

- **`docs/DATA_MODEL.md` is still the authority** on what a field means and
  which way it fails. A sample says what a correct document looks like; it does
  not say what happens when a field is missing, and that is the half that
  matters.
- **Every field is present, including the optional ones.** A sample with the
  optional half left out is a sample that teaches the reader the field does not
  exist.
- **Placeholder values only.** No real seller, no real email, no real store id
  — a file in this folder is public to anyone with the repo.
- **A document seeded by code does not belong here.** The demo business is
  `lib/features/mock_data/`, which is generated and stays that way.

| File | Document |
|---|---|
| `app_config/current.json` | `app_config/current` — the product's own switch board |
