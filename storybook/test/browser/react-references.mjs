import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { entries as aiEntries } from "../../../parity/src/official-ai-elements.mjs";
import { entries } from "../../../parity/src/official-shadcn.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const manifest = JSON.parse(readFileSync(join(repo, "registry/UPSTREAM.json")));
const previews = JSON.parse(
  readFileSync(join(repo, "registry/snapshot/index.json")),
);
const aiAudit = JSON.parse(
  readFileSync(join(here, "ai-component-audit.json")),
);

const aiStorybookNames = new Map(
  Object.entries(aiAudit).map(([storybook, contract]) => [contract.upstream, storybook]),
);

// AI Elements references are only official files discovered from the pinned
// manifest. Local-only fixtures remain usable in Storybook, but cannot make an
// upstream parity page exist.
export const officialAiReferences = new Set(
  aiEntries(manifest)
    .map(({ component, id }) => [aiStorybookNames.get(component), id])
    .filter(([storybook]) => storybook != null)
    .map(([storybook, id]) => `${storybook}.${id}`),
);

export const officialShadcnReferences = new Set(
  Object.entries(manifest.examples.shadcn).flatMap(([component, sources]) => {
    const storybook = previews[component]
      ? component
      : previews[`shadcn-${component}`]
        ? `shadcn-${component}`
        : null;

    return storybook ? entries(component, sources).map(({ id }) => `${storybook}.${id}`) : [];
  }),
);

export function hasOfficialReactReference(componentSource, name) {
  if (componentSource === "shadcn") return officialShadcnReferences.has(name);
  if (componentSource === "ai_elements") return officialAiReferences.has(name);
  return false;
}

// Both sources use only an official pinned entry. A local fixture can support
// development, but it cannot make a parity comparison or a Verified result.
export const reactReferences = new Set([...officialShadcnReferences, ...officialAiReferences]);
