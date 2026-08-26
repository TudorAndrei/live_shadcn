// Which registry a storybook example belongs to.
//
// `parity.spec.mjs` and `pixel.spec.mjs` gate `shadcn` only. AI Elements
// composes with `asChild`, and this repository pins shadcn's Base UI base,
// where that prop is dropped without a warning and without reaching the DOM —
// Base UI draws its own `<button>` around the element that was to become the
// trigger. The 49 AI Elements references stay on disk; nothing compares them.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

const inventory = JSON.parse(readFileSync(join(here, "../../../registry/INVENTORY.json")));

// The storybook knows a component by name; the registry knows it by source and
// name, because upstream publishes a `message` in each. The storybook calls
// those two `shadcn-message` and `ai_elements-message`.
const byName = new Map();

for (const { name, source } of inventory.components) {
  byName.set(name, byName.has(name) ? "ambiguous" : source);
}

/** The registry a storybook component belongs to, or null. */
export function source(component) {
  if (component.startsWith("shadcn-")) return "shadcn";
  if (component.startsWith("ai_elements-")) return "ai_elements";

  const found = byName.get(component);
  return found === "ambiguous" ? null : (found ?? null);
}

/** Whether the two upstream-comparing checks gate this component. */
export const gated = (component) => source(component) === "shadcn";
