import assert from "node:assert/strict";
import test from "node:test";

import { parityTimeoutMs } from "./parity-timeout.mjs";

test("parity timeout covers React and LiveView work for each visual state", () => {
  assert.equal(parityTimeoutMs(1), 32_000);
  assert.equal(parityTimeoutMs(12), 164_000);
});

test("parity timeout has a hard upper bound", () => {
  assert.equal(parityTimeoutMs(100), 300_000);
});

test("parity timeout rejects an invalid visual state count", () => {
  assert.throws(() => parityTimeoutMs(0), /positive integer/);
});
