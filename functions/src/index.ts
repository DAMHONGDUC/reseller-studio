/**
 * Seller OS Cloud Functions — the trusted half of the app.
 *
 * Everything here exists because a client must not be able to do it. The test
 * for whether something belongs in this codebase rather than in Flutter is
 * one question: **would a modified client be able to lie about it?**
 *
 * Things that answer yes, and therefore live here:
 *
 * - **Marketplace OAuth and every call that uses a token.** The plan is
 *   explicit that secrets never ship in the Flutter binary (§14, §32). The
 *   app asks the backend; the backend asks eBay.
 * - **Subscription state.** A client that could write its own plan tier would
 *   grant itself Business.
 * - **The audit log.** An entry a client writes can name any actor it likes,
 *   which makes it worthless as an audit log (§23).
 * - **Anything that must count across documents** — the last-owner check when
 *   demoting a member, free-tier inventory limits. Security rules can read
 *   one document, not aggregate a collection.
 * - **Cascading deletes.** Firestore does not cascade, so deleting a
 *   workspace has to walk its subcollections with the Admin SDK.
 *
 * Everything else belongs in the app, where it is faster and works offline.
 *
 * Functions are exported one per file from `src/`, and re-exported here.
 * Nothing is defined in this file — a single index that grew implementations
 * is a cold start that loads every dependency for every call.
 */

import { initializeApp } from 'firebase-admin/app';

initializeApp();

// Nothing is deployed yet. Add each function as its own module and re-export
// it here, e.g.:
//
//   export { connectMarketplace } from './marketplaces/connectMarketplace';
//   export { onOrderWritten } from './activity/onOrderWritten';
//   export { deleteWorkspace } from './workspace/deleteWorkspace';
export {};
