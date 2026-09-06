import assert from "node:assert/strict";
import test from "node:test";

import { regressions } from "./accessibility.mjs";

const violation = (id, targets) => ({
  id,
  help: `${id} help`,
  nodes: targets.map((target) => ({ target: [target], failureSummary: `${id} at ${target}` })),
});

test("inherits an upstream violation only at the same axe target", () => {
  const upstream = [violation("aria-valid-attr", ["#upstream-control"])];
  const port = [violation("aria-valid-attr", ["#port-control"])];

  assert.deepEqual(regressions(port, upstream), [
    'aria-valid-attr: aria-valid-attr help (port target ["#port-control"] has no matching upstream violation): aria-valid-attr at #port-control at #port-control',
  ]);
});

test("accepts the same upstream rule at the same target", () => {
  const upstream = [violation("aria-valid-attr", ["#control"])];
  const port = [violation("aria-valid-attr", ["#control"])];

  assert.deepEqual(regressions(port, upstream), []);
});

test("does not ignore a local color contrast violation", () => {
  const upstream = [];
  const port = [violation("color-contrast", [".muted-label"])];

  assert.deepEqual(regressions(port, upstream), [
    'color-contrast: color-contrast help (port target [".muted-label"] has no matching upstream violation): color-contrast at .muted-label at .muted-label',
  ]);
});

test("allows a color contrast violation only when upstream has it at that target", () => {
  const upstream = [violation("color-contrast", [".muted-label"])];
  const port = [violation("color-contrast", [".muted-label"])];

  assert.deepEqual(regressions(port, upstream), []);
});
