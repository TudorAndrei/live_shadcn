import assert from "node:assert/strict";
import test from "node:test";

import { pixelChromiumArgs } from "./chromium-resource-policy.mjs";

test("pixel Chromium limits renderer and raster work", () => {
  assert.ok(pixelChromiumArgs.includes("--renderer-process-limit=1"));
  assert.ok(pixelChromiumArgs.includes("--num-raster-threads=1"));
});
