// Which registry a storybook example belongs to.
//
// The verification pipeline compares shadcn ports with pinned upstream pages.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { officialShadcnReferences } from "./shadcn-references.mjs";

const here = dirname(fileURLToPath(import.meta.url));

const inventory = JSON.parse(readFileSync(join(here, "../../../registry/INVENTORY.json")));
const aiAudit = JSON.parse(readFileSync(join(here, "ai-component-audit.json"), "utf8"));

// The storybook knows a component by name; the registry knows it by source and
// name, because upstream publishes a `message` in each. The storybook calls
// those two `shadcn-message` and `ai_elements-message`.
const byName = new Map();

for (const { name, source } of inventory.components) {
  byName.set(name, byName.has(name) ? "ambiguous" : source);
}

// Composite documentation families have official React references but are not
// registry primitives. The reference catalog is the source of truth for
// browser parity, so it also decides their registry here.
const officialShadcnComponents = new Set(
  [...officialShadcnReferences].map((name) => name.slice(0, name.indexOf("."))),
);

/** The registry a storybook component belongs to, or null. */
export function source(component) {
  if (component === "code-block") return "ai_elements";
  if (component.startsWith("shadcn-")) return "shadcn";
  if (component.startsWith("ai_elements-")) return "ai_elements";

  const found = byName.get(component);
  if (found !== undefined) return found === "ambiguous" ? null : found;

  return officialShadcnComponents.has(component) ? "shadcn" : null;
}

/** Whether the two upstream-comparing checks gate this component. */
export const gated = (component) => source(component) === "shadcn";

const selectedSource = process.env.PREVIEW_SOURCE;
const shadcnSuites = selectedSource === "ai_elements" ? [] : [
  ...inventory.components.filter(({ source }) => source === "shadcn").map(({ name }) => `${name}.spec.mjs`),
  ...[...officialShadcnComponents].flatMap((name) => [`${name}.spec.mjs`, `${name.replace(/^shadcn-/, "")}.spec.mjs`]),
  ...["interaction-parity", "parity", "pixel", "rendered-output", "visual-states", "navigation"].map((name) => `${name}.spec.mjs`),
];
const aiSuites = selectedSource === "shadcn" ? [] : [
  ...Object.values(aiAudit).map(({ spec }) => spec).filter(Boolean),
];

export const verificationSpecFiles = [...new Set([
  ...shadcnSuites, ...aiSuites, "accessibility.spec.mjs",
])].sort().map((name) => `**/${name}`);
