import assert from "node:assert/strict";
import test from "node:test";

import { pixelTimeoutMs } from "./pixel-timeout.mjs";

test("pixel timeout keeps the current minimum for a small state set", () => {
  assert.equal(pixelTimeoutMs(1), 120_000);
});

test("pixel timeout covers Animation's eleven serial state captures", () => {
  assert.equal(pixelTimeoutMs(11), 240_000);
});
