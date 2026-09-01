/**
 * Where the functions a client addresses by name are deployed.
 *
 * **The app names a region and the backend must be in it, or every call 404s
 * with `not-found`** — `AppEnv.functionsRegion` says exactly that on the other
 * side of the wire. Nothing here set one, so every callable was deployed to
 * firebase-functions' default `us-central1` while the app asked
 * `asia-southeast1` for it. The failure is silent until the first call.
 *
 * A deliberate mirror of `FUNCTIONS_REGION` in the env files, the same shape
 * `seatsByPlan` has: two sides of a wire cannot share a constant.
 * `test/region.test.mjs` reads `env/env.example.json` and fails if they drift.
 *
 * **Triggers and the scheduler deliberately do not take this.** A Firestore
 * trigger has to sit in a region its database allows, which is Firebase's to
 * pick and not this file's to guess; nobody addresses one by region anyway.
 * What needs pinning is only what the app — or RevenueCat — dials directly.
 */
export const clientRegion = 'asia-southeast1';

/** Spread into every `onCall` and `onRequest`. */
export const clientFacing = { region: clientRegion } as const;
