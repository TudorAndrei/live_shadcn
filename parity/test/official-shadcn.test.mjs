import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

import { entries } from "../src/official-shadcn.mjs";

function pinnedExamples() {
  const upstream = JSON.parse(readFileSync(new URL("../../registry/UPSTREAM.json", import.meta.url)));
  const previews = JSON.parse(
    readFileSync(new URL("../../registry/snapshot/index.json", import.meta.url)),
  );
  const expected = new Map();

  for (const [component, sources] of Object.entries(upstream.examples.shadcn)) {
    const storybook = previews[component]
      ? component
      : previews[`shadcn-${component}`]
        ? `shadcn-${component}`
        : null;

    for (const { id, source } of entries(component, sources)) {
      expected.set(`${storybook}.${id}`, {
        source,
        storybook,
        id,
      });
    }
  }

  return { expected, previews };
}

test("official ids match the verifier and stay unique", () => {
  assert.deepEqual(entries("button", ["button-demo", "button-default", "button-rtl"]), [
    { id: "default", source: "button-demo" },
    { id: "button-default", source: "button-default" },
    { id: "rtl", source: "button-rtl" },
  ]);
});

test("keeps the Base interactive Chart preview as chart.demo", () => {
  assert.deepEqual(entries("chart", [{ id: "demo", source: "chart-demo" }]), [
    { id: "demo", source: "chart-demo" },
  ]);
});

test("keeps every Base Date Picker source under its published id", () => {
  assert.deepEqual(entries("date-picker", [
    "date-picker-demo", "date-picker-basic", "date-picker-range", "date-picker-dob",
    "date-picker-input", "date-picker-time", "date-picker-natural-language", "date-picker-rtl",
  ]), [
    { id: "default", source: "date-picker-demo" },
    { id: "basic", source: "date-picker-basic" },
    { id: "range", source: "date-picker-range" },
    { id: "dob", source: "date-picker-dob" },
    { id: "input", source: "date-picker-input" },
    { id: "time", source: "date-picker-time" },
    { id: "natural-language", source: "date-picker-natural-language" },
    { id: "rtl", source: "date-picker-rtl" },
  ]);
});

test("keeps both Base Data Table sources under their published ids", () => {
  assert.deepEqual(entries("data-table", ["data-table-demo", "data-table-rtl"]), [
    { id: "default", source: "data-table-demo" },
    { id: "rtl", source: "data-table-rtl" },
  ]);
});

test("docs-only families select the pinned React source", () => {
  const generator = readFileSync(new URL("../upstream.mjs", import.meta.url), "utf8");

  assert.match(generator, /Object\.keys\(manifest\.examples\.shadcn\)/);
  assert.match(generator, /sourceComponents/);
});

test("keeps a supplemental registry fixture under its explicit public id", () => {
  assert.deepEqual(
    entries("sonner", [
      {
        id: "basic",
        source: "shadcn/examples/sonner-example.tsx#SonnerBasic",
        reference: "shadcn/sonner#SonnerBasic",
      },
    ]),
    [
      {
        id: "basic",
        source: "shadcn/examples/sonner-example.tsx#SonnerBasic",
        reference: "shadcn/sonner#SonnerBasic",
      },
    ],
  );
});

test("keeps the shared Card RTL example with Card", () => {
  assert.deepEqual(entries("direction", ["card-rtl"]), []);
  assert.deepEqual(entries("card", ["card-demo", "card-rtl"]), [
    { id: "default", source: "card-demo" },
    { id: "rtl", source: "card-rtl" },
  ]);
});

test("the pinned shadcn catalog has a Storybook page for every official example", () => {
  const { expected, previews } = pinnedExamples();
  const missing = [];

  for (const { storybook, id, source } of expected.values()) {
    if (!storybook || !previews[storybook].includes(id)) {
      missing.push(`${storybook}.${id} (${source})`);
    }
  }

  assert.equal(expected.size, 463);
  assert.deepEqual(missing, []);
});

test("the official shadcn evidence map covers every pinned example", () => {
  const { expected } = pinnedExamples();
  const officialExamples = JSON.parse(
    readFileSync(new URL("../official-examples.json", import.meta.url)),
  );

  assert.deepEqual(Object.keys(officialExamples).sort(), [...expected.keys()].sort());

  for (const [key, { source }] of expected) {
    const expectedSource = source.startsWith("shadcn/")
      ? source
      : `shadcn_examples/${source}.tsx#`;

    assert.ok(officialExamples[key].startsWith(expectedSource), `${key} maps to ${source}`);
  }
});
