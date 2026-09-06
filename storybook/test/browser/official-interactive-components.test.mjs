import assert from "node:assert/strict";
import test from "node:test";

import {
  OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS,
  isOfficialInteractiveShadcnComponent,
} from "./official-interactive-components.mjs";
import { officialShadcnReferences } from "./react-references.mjs";

test("official interactive visual families come from the pinned React reference catalog", () => {
  const officialComponents = new Set(
    [...officialShadcnReferences].map((reference) => reference.slice(0, reference.indexOf("."))),
  );

  assert.ok(OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS.includes("data-table"));
  assert.ok(OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS.includes("dropdown-menu"));
  assert.ok(OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS.includes("questionnaire"));
  assert.ok(OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS.includes("native-select"));
  assert.deepEqual(new Set(OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS), officialComponents);
});

test("the generated visual-action manifest excludes a component without an official reference", () => {
  assert.equal(isOfficialInteractiveShadcnComponent("native-select"), true);
  assert.equal(isOfficialInteractiveShadcnComponent("not-a-component"), false);
});
