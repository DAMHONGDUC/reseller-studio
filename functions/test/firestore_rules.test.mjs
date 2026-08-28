import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

// The rules under test, read from the file that is actually deployed. Loading
// a copy would let the two drift, which is the one failure a rules test cannot
// afford: it would pass while production is open.
const RULES = readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8');

const WORKSPACE = 'ws-1';
const OWNER = 'uid-owner';
const ADMIN = 'uid-admin';
const MEMBER = 'uid-member';
const VIEWER = 'uid-viewer';
const OUTSIDER = 'uid-outsider';

let testEnv;

/** The workspace and its four roles, written with the rules switched off. */
async function seed() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await db.doc(`workspaces/${WORKSPACE}`).set({ name: 'Demo', ownerId: OWNER });

    const roles = {
      [OWNER]: 'owner',
      [ADMIN]: 'admin',
      [MEMBER]: 'member',
      [VIEWER]: 'viewer',
    };

    for (const [uid, role] of Object.entries(roles)) {
      await db.doc(`workspaces/${WORKSPACE}/members/${uid}`).set({ uid, role });
    }

    await db.doc(`workspaces/${WORKSPACE}/items/item-1`).set({ title: 'Jacket' });

    // One notification, written the way a Cloud Function writes it.
    await db.doc(`users/${MEMBER}/notifications/n-1`).set({
      type: 'orderCreated',
      workspaceId: WORKSPACE,
      title: 'New order',
      body: 'Sold: Jacket',
      readAt: null,
    });
  });
}

const as = (uid) => testEnv.authenticatedContext(uid).firestore();
const anonymous = () => testEnv.unauthenticatedContext().firestore();

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-seller-os',
    firestore: { rules: RULES },
  });

  await seed();
});

after(async () => {
  await testEnv.cleanup();
});

describe('membership is the only ACL', () => {
  it('lets every role read the business, viewer included', async () => {
    for (const uid of [OWNER, ADMIN, MEMBER, VIEWER]) {
      await assertSucceeds(as(uid).doc(`workspaces/${WORKSPACE}/items/item-1`).get());
    }
  });

  it('refuses a non-member, signed in or not', async () => {
    await assertFails(as(OUTSIDER).doc(`workspaces/${WORKSPACE}/items/item-1`).get());
    await assertFails(anonymous().doc(`workspaces/${WORKSPACE}/items/item-1`).get());
  });

  it('refuses a viewer every write — that is what viewer means', async () => {
    await assertFails(
      as(VIEWER).doc(`workspaces/${WORKSPACE}/items/item-2`).set({ title: 'New' }),
    );
  });

  it('lets a member write business records', async () => {
    await assertSucceeds(
      as(MEMBER).doc(`workspaces/${WORKSPACE}/items/item-3`).set({ title: 'New' }),
    );
  });
});

describe('nobody edits their own membership document', () => {
  // Hard rule 11. Without this clause a member sets their own role to owner
  // and every other rule in the file is decided by the document they just
  // rewrote.
  it('refuses a member promoting themselves', async () => {
    await assertFails(
      as(MEMBER).doc(`workspaces/${WORKSPACE}/members/${MEMBER}`).update({ role: 'owner' }),
    );
  });

  it('refuses even the owner editing their own', async () => {
    await assertFails(
      as(OWNER).doc(`workspaces/${WORKSPACE}/members/${OWNER}`).update({ role: 'admin' }),
    );
  });

  it('lets an admin change somebody else', async () => {
    await assertSucceeds(
      as(ADMIN).doc(`workspaces/${WORKSPACE}/members/${MEMBER}`).update({ role: 'viewer' }),
    );
  });
});

describe('creating a workspace', () => {
  it('only ever names the caller as owner', async () => {
    await assertSucceeds(
      as(OUTSIDER).doc('workspaces/ws-new').set({ name: 'Mine', ownerId: OUTSIDER }),
    );
    await assertFails(
      as(OUTSIDER).doc('workspaces/ws-stolen').set({ name: 'Theirs', ownerId: OWNER }),
    );
  });

  // The bootstrap clause, and the one place somebody writes their own
  // membership. It is what makes a new workspace reachable at all: `canAdmin`
  // reads the very document being created, so without it the first member
  // could never be written and the workspace would be unreadable forever.
  it('lets its owner write the first membership, as owner and nothing else', async () => {
    await assertSucceeds(
      as(OUTSIDER).doc(`workspaces/ws-new/members/${OUTSIDER}`).set({ role: 'owner' }),
    );
  });

  it('refuses that same write with any other role', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc('workspaces/ws-second')
        .set({ name: 'Second', ownerId: OUTSIDER });
    });

    await assertFails(
      as(OUTSIDER).doc(`workspaces/ws-second/members/${OUTSIDER}`).set({ role: 'member' }),
    );
  });

  it('refuses somebody the workspace does not name as owner', async () => {
    await assertFails(
      as(MEMBER).doc(`workspaces/ws-second/members/${MEMBER}`).set({ role: 'owner' }),
    );
  });

  it('refuses an update that reassigns the owner', async () => {
    await assertFails(
      as(ADMIN).doc(`workspaces/${WORKSPACE}`).update({ ownerId: ADMIN }),
    );
  });

  it('refuses a client deleting a workspace', async () => {
    await assertFails(as(OWNER).doc(`workspaces/${WORKSPACE}`).delete());
  });
});

describe('what only a Cloud Function may write', () => {
  it('refuses a client appending to the audit log', async () => {
    // Hard rule 12: an entry a client can write can name any actor it likes,
    // which makes the whole log worthless.
    await assertFails(
      as(OWNER).doc(`workspaces/${WORKSPACE}/activity/a-1`).set({ actorId: OWNER }),
    );
  });

  it('lets a member maintain seller-owned marketplace records', async () => {
    await assertSucceeds(
      as(OWNER).doc(`workspaces/${WORKSPACE}/marketplaces/ebay`).set({
        name: 'eBay',
        feeRate: 0.1325,
      }),
    );
  });

  it('refuses a client granting itself a plan', async () => {
    await assertFails(
      as(OWNER).doc(`workspaces/${WORKSPACE}/subscription/current`).set({ plan: 'business' }),
    );
  });
});

describe('user profiles', () => {
  it('lets somebody read and write only their own', async () => {
    await assertSucceeds(as(MEMBER).doc(`users/${MEMBER}`).set({ displayName: 'Me' }));
    await assertFails(as(MEMBER).doc(`users/${OWNER}`).get());
  });
});

describe('devices and the notification inbox', () => {
  it('lets somebody register a device token on their own record only', async () => {
    await assertSucceeds(
      as(MEMBER).doc(`users/${MEMBER}/devices/d-1`).set({ token: 'abc' }),
    );
    // A token is a way to push arbitrary text onto somebody's phone.
    await assertFails(as(MEMBER).doc(`users/${OWNER}/devices/d-1`).set({ token: 'abc' }));
    await assertFails(as(MEMBER).doc(`users/${OWNER}/devices/d-1`).get());
  });

  it('refuses a client creating a notification', async () => {
    // Same reasoning as the audit log: one a client can write can claim any
    // business made any sale.
    await assertFails(
      as(MEMBER).doc(`users/${MEMBER}/notifications/n-2`).set({ type: 'orderCreated' }),
    );
  });

  it('lets the reader mark one read, and nothing else', async () => {
    await assertSucceeds(
      as(MEMBER).doc(`users/${MEMBER}/notifications/n-1`).update({ readAt: new Date() }),
    );
    await assertFails(
      as(MEMBER).doc(`users/${MEMBER}/notifications/n-1`).update({ body: 'Sold: a car' }),
    );
    await assertFails(as(MEMBER).doc(`users/${MEMBER}/notifications/n-1`).delete());
  });

  it("refuses reading another person's inbox", async () => {
    await assertFails(as(OWNER).doc(`users/${MEMBER}/notifications/n-1`).get());
  });
});

describe('everything else is denied by default', () => {
  it('refuses a collection no rule names', async () => {
    await assertFails(as(OWNER).doc('secrets/s-1').get());
    await assertFails(as(OWNER).doc('secrets/s-1').set({ value: 1 }));
  });
});
