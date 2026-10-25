import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { entries } from "../../../parity/src/official-shadcn.mjs";

const repo = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const manifest = JSON.parse(readFileSync(join(repo, "registry/UPSTREAM.json")));
const previews = JSON.parse(readFileSync(join(repo, "registry/snapshot/index.json")));

// Shadcn's reference catalog is complete in the committed manifest. Reading it
// does not require downloaded sources from either registry.
export const officialShadcnReferences = new Set(
  Object.entries(manifest.examples.shadcn).flatMap(([component, sources]) => {
    const storybook = previews[`shadcn-${component}`]
      ? `shadcn-${component}`
      : previews[component]
        ? component
        : null;

    return storybook ? entries(component, sources).map(({ id }) => `${storybook}.${id}`) : [];
  }),
);
