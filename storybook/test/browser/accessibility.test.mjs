import assert from "node:assert/strict";
import test from "node:test";

import { regressions } from "./accessibility.mjs";

const violation = (id, targets, stableTargets = []) => ({
  id,
  help: `${id} help`,
  nodes: targets.map((target, index) => ({
    target: [target],
    stableTarget: stableTargets[index],
    failureSummary: `${id} at ${target}`,
  })),
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

test("accepts framework-specific selectors that resolve to the same stable target", () => {
  const stableTarget =
    "preview:sidebar > slot:sidebar-group:1 > slot:sidebar-menu";
  const upstream = [
    violation("list", [".cn-sidebar-menu:nth-child(1)"], [stableTarget]),
  ];
  const port = [
    violation("list", ['ul[data-phx-id="m9-phx-id"]'], [stableTarget]),
  ];

  assert.deepEqual(regressions(port, upstream), []);
});

test("reports equal rules at different stable targets", () => {
  const expected =
    'list: list help (port target ["preview:sidebar > slot:body"] has no matching upstream violation): ' +
    'list at ul[data-phx-id="m9-phx-id"] at ul[data-phx-id="m9-phx-id"]';
  const upstream = [
    violation("list", [".cn-sidebar-menu"], ["preview:sidebar > slot:header"]),
  ];
  const port = [
    violation("list", ['ul[data-phx-id="m9-phx-id"]'], ["preview:sidebar > slot:body"]),
  ];

  assert.deepEqual(regressions(port, upstream), [expected]);
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
