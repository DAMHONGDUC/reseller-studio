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
      await db.doc(`members/${WORKSPACE}_${uid}`).set({ uid, role, workspaceId: WORKSPACE });
    }

    await db.doc(`items/${WORKSPACE}_item-1`).set({ title: 'Jacket', workspaceId: WORKSPACE });

    await db.doc('app_config/current').set({ premium_enabled: true });

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
      await assertSucceeds(as(uid).doc(`items/${WORKSPACE}_item-1`).get());
    }
  });

  it('refuses a non-member, signed in or not', async () => {
    await assertFails(as(OUTSIDER).doc(`items/${WORKSPACE}_item-1`).get());
    await assertFails(anonymous().doc(`items/${WORKSPACE}_item-1`).get());
  });

  it('refuses a viewer every write — that is what viewer means', async () => {
    await assertFails(
      as(VIEWER).doc(`items/${WORKSPACE}_item-2`).set({ title: 'New', workspaceId: WORKSPACE }),
    );
  });

  it('lets a member write business records', async () => {
    await assertSucceeds(
      as(MEMBER).doc(`items/${WORKSPACE}_item-3`).set({ title: 'New', workspaceId: WORKSPACE }),
    );
  });
});

describe('a row cannot be moved into another business', () => {
  // The cost hard rule 14 accepts: ownership is a column now, so an update
  // that rewrites it is a record planted in somebody else's account. The rule
  // checks the stored row and the incoming one, which is the only reason this
  // fails (`docs/rules/BACKEND.md`).
  it('refuses an update that rewrites workspaceId', async () => {
    await assertFails(
      as(MEMBER)
        .doc(`items/${WORKSPACE}_item-1`)
        .update({ workspaceId: 'ws-somebody-else' }),
    );
  });

  // And the query half: a read without the filter picks up rows the caller
  // cannot see, fails on them, and takes the whole query down rather than
  // returning a subset.
  it('refuses a query with no workspace filter', async () => {
    await assertFails(as(MEMBER).collection('items').get());
    await assertSucceeds(
      as(MEMBER).collection('items').where('workspaceId', '==', WORKSPACE).get(),
    );
  });
});

describe('nobody edits their own membership document', () => {
  // Hard rule 11. Without this clause a member sets their own role to owner
  // and every other rule in the file is decided by the document they just
  // rewrote.
  it('refuses a member promoting themselves', async () => {
    await assertFails(
      as(MEMBER).doc(`members/${WORKSPACE}_${MEMBER}`).update({ role: 'owner' }),
    );
  });

  it('refuses even the owner editing their own', async () => {
    await assertFails(
      as(OWNER).doc(`members/${WORKSPACE}_${OWNER}`).update({ role: 'admin' }),
    );
  });

  it('lets an admin change somebody else', async () => {
    await assertSucceeds(
      as(ADMIN).doc(`members/${WORKSPACE}_${MEMBER}`).update({ role: 'viewer' }),
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
      as(OUTSIDER).doc(`members/ws-new_${OUTSIDER}`).set({ role: 'owner', workspaceId: 'ws-new' }),
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
      as(OUTSIDER).doc(`members/ws-second_${OUTSIDER}`).set({ role: 'member', workspaceId: 'ws-second' }),
    );
  });

  it('refuses somebody the workspace does not name as owner', async () => {
    await assertFails(
      as(MEMBER).doc(`members/ws-second_${MEMBER}`).set({ role: 'owner', workspaceId: 'ws-second' }),
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
      as(OWNER).doc(`activity/${WORKSPACE}_a-1`).set({ actorId: OWNER }),
    );
  });

  it('lets a member maintain seller-owned marketplace records', async () => {
    await assertSucceeds(
      as(OWNER).doc(`marketplaces/${WORKSPACE}_ebay`).set({
        name: 'eBay',
        feeRate: 0.1325,
      }),
    );
  });

  it('lets a member maintain business-owned carrier records', async () => {
    await assertSucceeds(
      as(OWNER).doc(`carriers/${WORKSPACE}_usps`).set({
        name: 'USPS',
      }),
    );
  });

  it('refuses a client granting itself a plan', async () => {
    await assertFails(
      as(OWNER).doc(`subscription/${WORKSPACE}_current`).set({ plan: 'premium' }),
    );
  });
});

describe('the Free ceilings are a boundary, not a UI decision', () => {
  // Plan §27. The client gate is what a seller sees; this is what a modified
  // client meets. A rule cannot count a collection, so the counting happens in
  // a trigger and the rule reads the verdict it wrote.
  //
  // Written as OWNER rather than MEMBER: an earlier suite demotes MEMBER to
  // viewer, and a viewer is refused every write for a reason that has nothing
  // to do with a ceiling.

  it('lets a create through while the workspace is under its ceiling', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`usage/${WORKSPACE}_current`)
        .set({ items: 3, orders: 1, itemsAtCeiling: false, ordersAtCeiling: false });
    });

    await assertSucceeds(
      as(OWNER).doc(`items/${WORKSPACE}_item-under`).set({ title: 'Jacket' }),
    );
  });

  it('refuses a create once the trigger says the ceiling is reached', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`usage/${WORKSPACE}_current`)
        .set({ items: 60, orders: 40, itemsAtCeiling: true, ordersAtCeiling: true });
    });

    await assertFails(
      as(OWNER).doc(`items/${WORKSPACE}_item-over`).set({ title: 'Jacket' }),
    );
    await assertFails(
      as(OWNER).doc(`orders/${WORKSPACE}_order-over`).set({ total: 1 }),
    );
  });

  it('still lets the seller edit and delete what they already have', async () => {
    // A downgrade never freezes existing rows — the same promise `PlanGate`
    // makes in the app. Deleting is how a seller gets back under the ceiling,
    // so refusing it would be a trap with no way out.
    await assertSucceeds(
      as(OWNER).doc(`items/${WORKSPACE}_item-1`).update({ title: 'Edited' }),
    );
    await assertSucceeds(
      as(OWNER).doc(`items/${WORKSPACE}_item-3`).delete(),
    );
  });

  it('fails open when the flag is missing, malformed or the document is gone', async () => {
    for (const usage of [{ items: 60 }, { itemsAtCeiling: 'yes' }, null]) {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const reference = context.firestore().doc(`usage/${WORKSPACE}_current`);

        await (usage === null ? reference.delete() : reference.set(usage));
      });

      await assertSucceeds(
        as(OWNER).doc(`items/${WORKSPACE}_item-open`).set({ title: 'Jacket' }),
      );
    }
  });

  it('refuses a client clearing its own ceiling flag', async () => {
    await assertFails(
      as(OWNER).doc(`usage/${WORKSPACE}_current`).set({ itemsAtCeiling: false }),
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

describe('app config needs no account', () => {
  it('lets a signed-out client read it', async () => {
    await assertSucceeds(anonymous().doc('app_config/current').get());
  });

  it('refuses every client the write, signed in or not', async () => {
    await assertFails(anonymous().doc('app_config/current').set({ premium_enabled: false }));
    await assertFails(as(OWNER).doc('app_config/current').set({ premium_enabled: false }));
  });
});

describe('everything else is denied by default', () => {
  it('refuses a collection no rule names', async () => {
    await assertFails(as(OWNER).doc('secrets/s-1').get());
    await assertFails(as(OWNER).doc('secrets/s-1').set({ value: 1 }));
  });
});
