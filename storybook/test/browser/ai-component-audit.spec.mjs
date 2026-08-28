import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";

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

test("every AI Elements story has pinned upstream and independent checks", () => {
  expect(Object.keys(audit).sort()).toEqual(aiComponents);
  expect(upstream.sources.ai_elements.ref).toMatch(/^[0-9a-f]{40}$/);

  for (const [component, contract] of Object.entries(audit)) {
    const upstreamKey = `ai_elements/${contract.upstream}.tsx`;
    expect(upstream.files[upstreamKey], `${component} has no pinned source`).toBeTruthy();
    expect(
      existsSync(join(root, "registry/upstream", upstreamKey)),
      `${component} has no local pinned source`,
    ).toBe(true);

    for (const example of previews[component]) {
      expect(
        existsSync(join(root, "parity/src/examples", `${component}.${example}.tsx`)),
        `${component}/${example} has no React reference`,
      ).toBe(true);
    }

    if (contract.contract === "interactive") {
      expect(
        existsSync(join(here, contract.spec)),
        `${component} has no behavior test`,
      ).toBe(true);
    }
  }
});
