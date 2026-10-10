# CLAUDE.md — sourcing

Rules specific to buying stock: sources, purchases and the "Should I buy
this?" evaluator. The root `CLAUDE.md` still applies in full; this file only
holds what would be wrong to generalise.

## The evaluator reads top to bottom: inputs, then the answer

Owner's rule, and it **reverses "the answer, above the inputs"**.
`PurchaseEvaluatorScreen` puts the form first and the verdict under it, so the
screen reads in the order the seller works — type the prices, read what they
come to.

- **The sold-before card stays above the form.** It is what a scan found, and
  it is what filled the sale price in; it explains the form, not the verdict.
- **The pinned Scan button hides while the keyboard is up.** A button riding
  on top of the keyboard covers the field being typed into and the verdict
  under it; Scan is what a seller reaches for before typing, never during.
- `test/features/sourcing/purchase_evaluator_screen_test.dart` pins both.
