/**
 * Where the functions a client addresses by name are deployed.
 *
 * **The app names a region and the backend must be in it, or every call 404s
 * with `not-found`** — `AppEnv.functionsRegion` says exactly that on the other
 * side of the wire. Nothing here set one, so every callable took
 * firebase-functions' default while the app asked for somewhere else, and
 * `deleteAccount` answered `not-found` to the first seller who tried it.
 *
 * **It is the region the Firestore database is in** — owner's rule. The
 * triggers and the scheduler were already there, so putting the callables
 * anywhere else buys every read and write inside one a round trip between
 * continents, and the launch markets are the United States and the United
 * Kingdom. Pinning it explicitly rather than leaning on the default is still
 * the point: a default is not an agreement between two sides of a wire.
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
export const clientRegion = 'us-central1';

/** Spread into every `onCall` and `onRequest`. */
export const clientFacing = { region: clientRegion } as const;
