import assert from "node:assert/strict";
import test from "node:test";

import { assertVerificationInvocation } from "./server-policy.mjs";

test("the browser config accepts a managed verifier", () => {
  assert.doesNotThrow(() =>
    assertVerificationInvocation({ LIVE_SHADCN_MANAGED_SERVERS: "1" }),
  );
});

test("the browser config accepts the lease-owning wrapper", () => {
  assert.doesNotThrow(() =>
    assertVerificationInvocation({ LIVE_SHADCN_BROWSER_VERIFY_WRAPPER: "1" }),
  );
});

test("the browser config rejects an unmanaged direct invocation", () => {
  assert.throws(
    () => assertVerificationInvocation({}),
    /npm run verify/,
  );
});
