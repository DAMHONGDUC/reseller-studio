# Sample data

One file per Firestore document, every field filled in. The path mirrors the collection: `sample_data/<collection>/<documentId>.json`.

**A reference, not a fixture.** Nothing reads these files — no app, test or seed script. They let a document created by hand in the Firebase console be copied, not remembered, and make its shape reviewable in a diff.

- **`docs/architecture/DATA_MODEL.md` stays the authority** on what a field means and which way it fails. A sample shows a correct document, not what a missing field does — the half that matters.
- **Every field is present, optional ones too.** A sample missing the optional half teaches that those fields do not exist.
- **Placeholder values only.** No real seller, email or store id — this folder is public to anyone with the repo.
- **A document seeded by code does not belong here.** The demo business is `lib/features/mock_data/`, generated, and stays that way.

| File | Document |
|---|---|
| `app_config/current.json` | `app_config/current` — the product's own switchboard |
