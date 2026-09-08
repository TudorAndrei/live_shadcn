// Every preview page has an axe-core check. Official pages compare against the
// pinned upstream page. Declared local-only pages have no official comparison,
// so they must have no local markup violation.
//
// A component with no behaviour still has an accessibility contract, and this
// is the check that applies to all of them: the markup a reader gets, in a real
// browser, with a real accessibility tree. A port with an official page can
// inherit an upstream violation only at the same axe target. A local-only page
// must have no violations.
//
// Components that also have behaviour get a suite of their own beside this one.
// This file never replaces that; it is the floor, not the ceiling.
//
// `mix ui.verify` runs it filtered to one component through PREVIEW_COMPONENT.

import { readFileSync } from "node:fs";
import { beginStateCoverage } from "./report-provenance.mjs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

import { regressions } from "./accessibility.mjs";
import { source } from "./registries.mjs";
import { connected } from "./live.mjs";
import {
  enterVisualState,
  visualStateIdentity,
  visualStates,
  waitForTimedExample,
} from "./visual-states.mjs";

const only = process.env.PREVIEW_COMPONENT;
const onlyExample = process.env.PREVIEW_EXAMPLE;
const selectedExamples = new Set(
  (process.env.PREVIEW_EXAMPLES || "").split(",").filter(Boolean),
);
const selected = new Set(
  (process.env.PREVIEW_COMPONENTS || "").split(",").filter(Boolean),
);

// Written by `mix snapshot`, and read here rather than fetched: Playwright
// collects tests before it starts the server.
const index = join(dirname(fileURLToPath(import.meta.url)), "../../../registry/snapshot/index.json");
const previews = JSON.parse(readFileSync(index, "utf8"));
const aiAudit = JSON.parse(
  readFileSync(join(dirname(fileURLToPath(import.meta.url)), "ai-component-audit.json"), "utf8"),
);
const localOnly = new Set(
  Object.entries(aiAudit).flatMap(([component, contract]) =>
    (contract.local_only_examples || []).map((example) => `${component}.${example}`),
  ),
);

const pages = Object.entries(previews)
  .filter(([component]) => source(component) === "shadcn")
  .filter(([component]) => !only || component === only)
  .filter(([component]) => selected.size === 0 || selected.has(component))
  .flatMap(([component, examples]) => examples.map((example) => ({ component, example })))
  .filter(({ example }) => selectedExamples.size === 0 || selectedExamples.has(example))
  .filter(({ example }) => !onlyExample || example === onlyExample);

if (pages.length === 0) {
  test("there is an example to check", () => {
    throw new Error(
      only
        ? `no preview page for ${only}. Add an example to StorybookWeb.Examples.`
        : "no preview pages at all. Run `mix snapshot` in storybook/ first.",
    );
  });
}

for (const { component, example } of pages) {
  const hasLocalOnlyPolicy = localOnly.has(`${component}.${example}`);
  const contract = hasLocalOnlyPolicy ? "local accessibility" : "upstream accessibility";

  test(`${component} / ${example} has the ${contract} contract`, async (
    { page },
    testInfo,
  ) => {
    const path = `/preview/${component}/${example}`;
    const selector = `[data-preview='${component}']`;

    if (hasLocalOnlyPolicy) {
      const portStates = await statesAt(page, path, selector, true);
      const coverage = beginStateCoverage(testInfo, `${component}.${example}`,
        portStates.map((state) => JSON.stringify(visualStateIdentity(state))));

      for (const state of portStates) {
        const port = await scan(page, path, selector, state, true);
        coverage.complete(JSON.stringify(visualStateIdentity(state)));
        expect(port, `${component}/${example}/${state.name} has an accessibility violation`).toEqual([]);
      }

      return;
    }

    const upstreamURL = `${testInfo.project.use.parityURL}${path}`;
    const upstreamStates = await statesAt(page, upstreamURL, selector);
    const portStates = await statesAt(page, path, selector, true);

    expect(portStates.map(visualStateIdentity)).toEqual(upstreamStates.map(visualStateIdentity));

    const added = [];
    const coverage = beginStateCoverage(testInfo, `${component}.${example}`,
      upstreamStates.map((state) => JSON.stringify(visualStateIdentity(state))));

    for (const state of upstreamStates) {
      const upstream = await scan(page, upstreamURL, selector, state);
      const port = await scan(page, path, selector, state, true);
      added.push(...regressions(port, upstream).map((failure) => `${state.name}: ${failure}`));
      coverage.complete(JSON.stringify(visualStateIdentity(state)));
    }

    expect(added).toEqual([]);
  });
}

async function statesAt(page, url, selector, live = false) {
  await page.goto(url);
  if (live) await connected(page);
  return visualStates(page, selector);
}

async function scan(page, url, selector, state, live = false) {
  await page.goto(url);
  if (live) await connected(page);
  // A preview can contain only fixed, absolute children. It is then present
  // in the accessibility tree but has no box of its own to make visible.
  await expect(page.locator(selector)).toBeAttached();
  await enterVisualState(page, selector, state);
  await waitForTimedExample(page, selector);

  const result = await new AxeBuilder({ page })
    .include(selector)
    .include("[data-slot]")
    .analyze();

  return stableViolations(page, result.violations);
}

async function stableViolations(page, violations) {
  return Promise.all(
    violations.map(async (violation) => ({
      ...violation,
      nodes: await Promise.all(
        violation.nodes.map(async (node) => ({
          ...node,
          stableTarget: await stableTarget(page, node.target),
        })),
      ),
    })),
  );
}

async function stableTarget(page, target) {
  if (
    !Array.isArray(target) ||
    target.length !== 1 ||
    typeof target[0] !== "string"
  )
    return null;

  try {
    return await page.locator(target[0]).first().evaluate((element) => {
      const segments = [];

      for (let current = element; current; current = current.parentElement) {
        const preview = current.getAttribute("data-preview");
        const slot = current.getAttribute("data-slot");

        if (preview) {
          segments.unshift(`preview:${preview}`);
          break;
        }

        if (slot) {
          const peers = current.parentElement
            ? [...current.parentElement.children].filter(
                (candidate) => candidate.getAttribute("data-slot") === slot,
              )
            : [current];
        const occurrence =
          peers.length > 1 ? `:${peers.indexOf(current) + 1}` : "";
          segments.unshift(`slot:${slot}${occurrence}`);
        }
      }

      if (!element.hasAttribute("data-slot") && !element.hasAttribute("data-preview")) {
        const text = element.textContent.replace(/\s+/g, " ").trim().slice(0, 80);
        const role = element.getAttribute("role");
        const peers = element.parentElement
          ? [...element.parentElement.children].filter(
              (candidate) =>
                candidate.tagName === element.tagName && candidate.getAttribute("role") === role,
            )
          : [element];
        const occurrence =
          peers.length > 1 ? `:${peers.indexOf(element) + 1}` : "";
        segments.push(
          `node:${element.tagName.toLowerCase()}:${role || ""}:${text}${occurrence}`,
        );
      }

      return segments.length > 0 ? segments.join(" > ") : null;
    });
  } catch {
    return null;
  }
}
