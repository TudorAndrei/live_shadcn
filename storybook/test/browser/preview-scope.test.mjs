import assert from "node:assert/strict";
import test from "node:test";

import { hasScopeFilter, inScope, noScopedPagesMessage, scopeFromEnvironment } from "./preview-scope.mjs";

const source = (component) => (component === "local" ? "ai_elements" : "shadcn");

test("a selected example does not make another budget stale", () => {
  const scope = scopeFromEnvironment({
    PREVIEW_COMPONENT: "input-otp",
    PREVIEW_EXAMPLES: "default,invalid",
  });

  assert.equal(inScope("input-otp.default", scope, source), true);
  assert.equal(inScope("input-otp.form", scope, source), false);
});

test("selected examples scope stale parity divergences", () => {
  const scope = scopeFromEnvironment({
    PREVIEW_COMPONENT: "input-otp",
    PREVIEW_EXAMPLES: "default,invalid",
  });
  const compared = new Set(["input-otp.default", "input-otp.invalid"]);
  const divergences = ["input-otp.default", "input-otp.form", "button.default"];

  const stale = divergences
    .filter((name) => inScope(name, scope, source))
    .filter((name) => !compared.has(name));

  assert.deepEqual(stale, []);
});

test("a parity scope intersects every component, example, and source filter", () => {
  const scope = scopeFromEnvironment({
    PREVIEW_COMPONENT: "input-otp",
    PREVIEW_COMPONENTS: "input-otp,button",
    PREVIEW_EXAMPLE: "form",
    PREVIEW_EXAMPLES: "form,rtl",
    PREVIEW_SOURCE: "shadcn",
  });

  assert.equal(inScope("input-otp.form", scope, source), true);
  assert.equal(inScope("input-otp.rtl", scope, source), false);
  assert.equal(inScope("button.form", scope, source), false);
  assert.equal(inScope("local.form", scope, source), false);
});

test("an unfiltered run stays strict and a filtered empty run names its scope", () => {
  const unfiltered = scopeFromEnvironment({});
  const filtered = scopeFromEnvironment({PREVIEW_EXAMPLES: "missing"});
  const compared = new Set(["input-otp.default"]);
  const stale = ["input-otp.default", "input-otp.form"]
    .filter((name) => inScope(name, unfiltered, source))
    .filter((name) => !compared.has(name));

  assert.equal(hasScopeFilter(unfiltered), false);
  assert.equal(hasScopeFilter(filtered), true);
  assert.deepEqual(stale, ["input-otp.form"]);
  assert.equal(noScopedPagesMessage("parity", filtered), "no parity preview pages match this filter.");
});
