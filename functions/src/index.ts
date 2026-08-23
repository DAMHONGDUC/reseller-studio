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

// Membership. `onMemberWritten` is what keeps `users/{uid}.workspaceIds` in
// step — without it a seller only sees the businesses they created, never the
// ones they were invited to.
export { onMemberWritten } from './workspace/onMemberWritten';

// Deleting one business without deleting the account with it. Firestore does
// not cascade, so `workspaces/{id}` is `allow delete: if false` for clients
// and the subcollections are walked here.
export { deleteWorkspace } from './workspace/deleteWorkspace';

// Team. All three are callables because `firestore.rules` denies clients
// `invites/` and anyone's own membership document, and because the seat limit
// and the last-owner check both need a count rules cannot take.
export { inviteMember } from './team/inviteMember';
export { acceptInvite } from './team/acceptInvite';
export { removeMember } from './team/removeMember';

// Account deletion. App Store guideline 5.1.1(v) wants the account *and its
// data* gone, and Firestore does not cascade — so the subcollections and the
// Storage objects are walked with the Admin SDK.
export { deleteAccount } from './account/deleteAccount';

// Audit log. Written only here, so `actorId` cannot be forged (hard rule 12).
export {
  onItemWritten,
  onOrderWritten,
  onListingWritten,
} from './activity/onRecordWritten';

// Notifications (§22). The inbox document is written first and the push is a
// copy of it — a push is best-effort, and a design where it *is* the
// notification is one that turns itself off when permission does.
export {
  onOrderCreated,
  onOfferCreated,
  onMemberJoined,
} from './notifications/onRecordCreated';
export { dailyDigest } from './notifications/dailyDigest';

// Still to write: marketplace OAuth and sync, and the RevenueCat webhook that
// mirrors entitlement into Firestore.
