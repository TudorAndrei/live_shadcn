import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import assert from "node:assert/strict";

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
  assert.deepEqual(Object.keys(audit).sort(), aiComponents);
  assert.match(upstream.sources.ai_elements.ref, /^[0-9a-f]{40}$/);
  assert.equal(officialEntries.length, 84);
  assert.deepEqual(aiDiscoveryProblems(upstream), [], "AI example discovery has an ambiguous pinned relationship");
  assert.deepEqual(
    officialEntries.map(({ component }) => component).filter((component) => !auditedUpstreams.has(component)),
    [],
  );

  for (const [component, contract] of Object.entries(audit)) {
    const upstreamKey = `ai_elements/${contract.upstream}.tsx`;
    assert.ok(upstream.files[upstreamKey], `${component} has no pinned source`);
    assert.ok(existsSync(join(root, "registry/upstream", upstreamKey)), `${component} has no local pinned source`);

    const official = officialByUpstream.get(contract.upstream) || [];
    const local = previews[component] || [];
    const declared = contract.component_examples;
    const missing = official.filter(({ id }) => !local.includes(id));

    assert.deepEqual(
      missing.map(({ id, source: exampleSource }) => `${id} (${exampleSource})`),
      [], `${component} is missing HEEx previews for pinned official examples`,
    );

    const localOnly = contract.local_only_examples || [];

    assert.equal(new Set(localOnly).size, localOnly.length, `${component} repeats a local-only HEEx name`);

    if (declared) {
      assert.deepEqual([...declared].sort(), [...local].sort(),
        `${component} component_examples must describe its local HEEx previews`);
    }

    assert.deepEqual(
      local.filter((example) => !official.some(({ id }) => id === example) && !localOnly.includes(example)),
      [], `${component} has local HEEx previews without official or local-only policy`,
    );

    if (official.length === 0) {
      assert.notDeepEqual(localOnly, [], `${component} has no official examples and requires local-only policy`);
    }

    for (const example of localOnly) {
      const name = component + "." + example;

      assert.ok(local.includes(example), `${name} is local-only but has no HEEx preview`);
      assert.equal(official.some(({ id }) => id === example), false,
        `${component}.${example} is local-only but has an official pinned example`);
    }

    assert.match(contract.spec, /\.spec\.mjs$/, `${component} has no authored contract suite`);
    assert.ok(existsSync(join(here, contract.spec)), `${component} has no contract test`);
  }
});
