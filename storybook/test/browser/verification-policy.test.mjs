import assert from "node:assert/strict";
import test from "node:test";

import { comparisonApplies, policy } from "./verification-policy.mjs";

test("Sonner has React comparison because pinned source publishes examples", () => {
  assert.equal(comparisonApplies("shadcn", "sonner"), true);
  assert.equal(policy("shadcn", "sonner").kind, "standard");
});

test("Direction has no React comparison because it renders no DOM", () => {
  assert.equal(comparisonApplies("shadcn", "direction"), false);
});

test("normal components keep React comparison", () => {
  assert.equal(comparisonApplies("shadcn", "button"), true);
});

test("an approved AI local fixture has no React comparison", () => {
  assert.equal(comparisonApplies("ai_elements", "edge", "animated"), false);
  assert.equal(comparisonApplies("ai_elements", "edge", "default"), false);
  assert.equal(comparisonApplies("ai_elements", "persona", "default"), false);
});
