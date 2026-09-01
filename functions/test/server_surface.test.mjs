import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';

import * as functions from '../lib/index.js';
import { clientRegion } from '../lib/lib/runtime.js';

// The compiled modules, not the source: this suite runs under plain node, and
// `npm run build` is what CI runs before it.

/** Everything a client or a vendor dials directly, by name and by region. */
const clientFacing = Object.entries(functions).filter(
  ([, fn]) =>
    fn?.__endpoint?.callableTrigger !== undefined ||
    fn?.__endpoint?.httpsTrigger !== undefined,
);

describe('where the functions a client dials are deployed', () => {
  it('finds the callables and the webhook at all', () => {
    // A guard on the guard: if the shape of `__endpoint` ever changes, the
    // filter above would quietly match nothing and every assertion below
    // would pass over an empty list.
    assert.ok(clientFacing.length >= 6, `found ${clientFacing.length}`);
  });

  it('pins every one of them to one region', () => {
    // Without this the app 404s with `not-found` on the first call: v2
    // defaults to us-central1 while `AppEnv.functionsRegion` asks for
    // somewhere else, and nothing fails until a seller taps the button.
    for (const [name, fn] of clientFacing) {
      assert.deepEqual(fn.__endpoint.region, [clientRegion], `${name} region`);
    }
  });

  it('agrees with the region the app is built to call', () => {
    // The two sides of a wire cannot share a constant, so this is the seam
    // where the deliberate mirror is checked. `env.example.json` is the
    // template every flavour file is filled in from.
    const env = JSON.parse(
      readFileSync(new URL('../../env/env.example.json', import.meta.url), 'utf8'),
    );

    assert.equal(clientRegion, env.FUNCTIONS_REGION);
  });
});

describe('every callable the app names exists here', () => {
  // `CallableConstant`'s own doc comment says it: a name that disagrees is
  // not a compile error on either side, it is a `not-found` at the moment a
  // seller taps the button. This is the only place the two lists meet.
  const dart = readFileSync(
    new URL('../../lib/core/constants/callable_constant.dart', import.meta.url),
    'utf8',
  );
  const named = [...dart.matchAll(/static const String \w+ = '([^']+)';/g)].map(
    (match) => match[1],
  );

  it('reads the app\'s list at all', () => {
    assert.ok(named.length >= 5, `found ${named.length}`);
  });

  it('exports one callable per name, and no name is a typo', () => {
    for (const name of named) {
      assert.ok(functions[name], `${name} is not exported`);
      assert.ok(
        functions[name].__endpoint?.callableTrigger !== undefined,
        `${name} is exported but is not a callable`,
      );
    }
  });
});
