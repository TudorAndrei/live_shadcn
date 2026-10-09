// Generic semantic behaviour parity for every official shadcn example.
// `mix ui.verify` always passes one PREVIEW_COMPONENT value. Component suites
// run in addition to this common semantic check.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";

import {
  discoverInteractionProbes,
  enterInteractionProbe,
  probeIdentity,
  scopedInteractionPages,
} from "./interaction-parity.mjs";
import { connected, referenceReady } from "./live.mjs";
import { installBrowserFixtures } from "./visual-states.mjs";
import { hasScopeFilter, scopeFromEnvironment } from "./preview-scope.mjs";
import { hasOfficialReactReference } from "./react-references.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const previews = JSON.parse(readFileSync(join(here, "../../../registry/snapshot/index.json"), "utf8"));
const scope = scopeFromEnvironment();
const component = scope.only;
const pages = hasScopeFilter(scope)
  ? scopedInteractionPages(previews, scope, hasOfficialReactReference)
  : [];

if (!hasScopeFilter(scope)) {
  test("generic interaction parity is run by the verifier", () => {
    test.skip(true, "mix ui.verify supplies PREVIEW_COMPONENT for this suite");
  });
} else if (pages.length === 0) {
  test("the scoped shadcn component has official previews", () => {
    throw new Error(`${component} has no official React preview to compare`);
  });
}

for (const { component, example } of pages) {
  test(`${component} / ${example} keeps inferred interaction semantics`, async ({ page }, testInfo) => {
    await installBrowserFixtures(page);
    const selector = `[data-preview='${component}']`;
    const reactURL = `${testInfo.project.use.parityURL}/preview/${component}/${example}`;
    const phoenixURL = `/preview/${component}/${example}`;

    await page.goto(reactURL);
    await referenceReady(page);
    const reactProbes = await discoverInteractionProbes(page.locator(selector));

    await page.goto(phoenixURL);
    await connected(page);
    const phoenixProbes = await discoverInteractionProbes(page.locator(selector));

    expect(
      phoenixProbes.map(probeIdentity),
      `${component}/${example} must expose the same safe interaction probes as React`,
    ).toEqual(reactProbes.map(probeIdentity));

    for (const probe of reactProbes) {
      await page.goto(reactURL);
      await referenceReady(page);
      const react = await enterInteractionProbe(page, selector, probe);

      await page.goto(phoenixURL);
      await connected(page);
      const phoenix = await enterInteractionProbe(page, selector, probe);

      expect(
        phoenix,
        `${component}/${example}/${probe.kind}/${probe.name || probe.index} has different observable semantics`,
      ).toEqual(react);
    }
  });
}
