import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";

import {
  entries as aiEntries,
  problems as aiDiscoveryProblems,
} from "../../../parity/src/official-ai-elements.mjs";
import { source } from "./registries.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "../../..");
const audit = JSON.parse(readFileSync(join(here, "ai-component-audit.json"), "utf8"));
const previews = JSON.parse(
  readFileSync(join(root, "registry/snapshot/index.json"), "utf8"),
);
const upstream = JSON.parse(
  readFileSync(join(root, "registry/UPSTREAM.json"), "utf8"),
);

const aiComponents = Object.keys(previews)
  .filter((component) => source(component) === "ai_elements")
  .sort();

const officialEntries = aiEntries(upstream);
const officialByUpstream = new Map();
const auditedUpstreams = new Set(Object.values(audit).map(({ upstream: component }) => component));

for (const entry of officialEntries) {
  officialByUpstream.set(entry.component, [
    ...(officialByUpstream.get(entry.component) || []),
    entry,
  ]);
}

test("every AI Elements story has pinned upstream and independent checks", () => {
  expect(Object.keys(audit).sort()).toEqual(aiComponents);
  expect(upstream.sources.ai_elements.ref).toMatch(/^[0-9a-f]{40}$/);
  expect(officialEntries).toHaveLength(84);
  expect(aiDiscoveryProblems(upstream), "AI example discovery has an ambiguous pinned relationship").toEqual([]);
  expect(
    officialEntries.map(({ component }) => component).filter((component) => !auditedUpstreams.has(component)),
  ).toEqual([]);

  for (const [component, contract] of Object.entries(audit)) {
    const upstreamKey = `ai_elements/${contract.upstream}.tsx`;
    expect(upstream.files[upstreamKey], `${component} has no pinned source`).toBeTruthy();
    expect(
      existsSync(join(root, "registry/upstream", upstreamKey)),
      `${component} has no local pinned source`,
    ).toBe(true);

    const official = officialByUpstream.get(contract.upstream) || [];
    const local = previews[component] || [];
    const declared = contract.component_examples;
    const missing = official.filter(({ id }) => !local.includes(id));

    expect(
      missing.map(({ id, source: exampleSource }) => `${id} (${exampleSource})`),
      `${component} is missing HEEx previews for pinned official examples`,
    ).toEqual([]);

    const localOnly = contract.local_only_examples || [];

    expect(new Set(localOnly).size, `${component} repeats a local-only HEEx name`).toBe(localOnly.length);

    if (declared) {
      expect([...declared].sort(), `${component} component_examples must describe its local HEEx previews`).toEqual(
        [...local].sort(),
      );
    }

    expect(
      local.filter((example) => !official.some(({ id }) => id === example) && !localOnly.includes(example)),
      `${component} has local HEEx previews without official or local-only policy`,
    ).toEqual([]);

    if (official.length === 0) {
      expect(localOnly, `${component} has no official examples and requires local-only policy`).not.toEqual([]);
    }

    for (const example of local) {
      const name = component + "." + example;
      const fixture = join(root, "parity/src/examples", name + ".tsx");

      expect(existsSync(fixture), name + " has no React reference").toBe(true);

      const expected = official.find(({ id }) => id === example);

      if (expected) {
        expect(readFileSync(fixture, "utf8"), `${name} must load its pinned source`).toContain(
          'from "@upstream/ai_examples/' + expected.source + '";',
        );
      } else {
        expect(
          localOnly,
          name + " is local-only. Add it to local_only_examples; it cannot provide official parity.",
        ).toContain(example);
      }
    }

    for (const example of localOnly) {
      const name = component + "." + example;

      expect(local, `${name} is local-only but has no HEEx preview`).toContain(example);
      expect(existsSync(join(root, "parity/src/examples", name + ".tsx")), name + " has no local fixture").toBe(true);
      expect(
        official.some(({ id }) => id === example),
        `${component}.${example} is local-only but has an official pinned example`,
      ).toBe(false);
    }

    if (contract.contract === "interactive") {
      expect(
        existsSync(join(here, contract.spec)),
        `${component} has no behavior test`,
      ).toBe(true);
    }
  }
});
