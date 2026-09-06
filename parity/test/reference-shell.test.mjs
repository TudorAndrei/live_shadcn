import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const source = (path) => readFileSync(new URL(path, import.meta.url), "utf8");

test("the React and Phoenix preview shells keep the same hidden heading outline", () => {
  const react = source("../src/reference-page.tsx");
  const phoenix = source("../../storybook/lib/storybook_web/live/preview_live.ex");

  assert.match(react, /<h1 className="sr-only">\{component\}<\/h1>/);
  assert.match(react, /<h2 className="sr-only">\{id\}<\/h2>/);
  assert.match(phoenix, /<h1 class="sr-only">\{@component\}<\/h1>/);
  assert.match(phoenix, /<h2 class="sr-only">\{@example\.title\}<\/h2>/);
});

test("reference shell headings stay outside the parity and pixel selector root", () => {
  const react = source("../src/reference-page.tsx");
  const heading = react.indexOf('<h1 className="sr-only">');
  const preview = react.indexOf("data-preview={component}");

  assert.ok(heading >= 0, "the reference shell must include an h1");
  assert.ok(preview > heading, "the reference preview root must stay after the heading shell");
});
