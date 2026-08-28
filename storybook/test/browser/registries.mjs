// Which registry a storybook example belongs to.
//
// Both registries must pass the checks that render upstream. A reference that
// needs a documented normalization must make that rule in the comparison. It
// must not turn off checks for its complete registry.

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
export const gated = (component) => source(component) !== null;
