import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { gated, source, verificationSpecFiles } from "./registries.mjs";
import { hasOfficialReactReference } from "./react-references.mjs";

const here = dirname(fileURLToPath(import.meta.url));

test("verification collects both sources and their shared check suites", () => {
  for (const name of ["button", "message", "data-table", "typography", "accessibility", "parity", "pixel", "ai_elements-message", "voice-selector"]) {
    assert.ok(verificationSpecFiles.includes(`**/${name}.spec.mjs`), name);
  }
  assert.equal(gated("button"), true);
  assert.equal(gated("ai_elements-message"), false);
});

test("documented shadcn Typography has the upstream comparison gate", () => {
  assert.equal(source("typography"), "shadcn");
  assert.equal(gated("typography"), true);
});

test("docs-only official families resolve from their official references", () => {
  for (const component of ["data-table", "date-picker", "typography"]) {
    assert.equal(source(component), "shadcn", component);
    assert.equal(gated(component), true, component);
  }

  assert.equal(source("unknown-docs-family"), null);
  assert.equal(gated("unknown-docs-family"), false);
});

test("all Typography examples have strict pixel and official source registration", () => {
  const snapshots = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json"), "utf8"));
  const budget = JSON.parse(readFileSync(join(here, "pixel-budget.json"), "utf8"));

  assert.equal(snapshots.typography.length, 15);

  for (const example of snapshots.typography) {
    const name = `typography.${example}`;
    assert.equal(hasOfficialReactReference("shadcn", name), true, name);
    assert.equal(budget.budgets[name], 0, name);
  }
});
