import assert from "node:assert/strict";
import test from "node:test";
import { directEnvelope } from "./direct-report.mjs";

const index = { button: ["default", "sizes"], "shadcn-message": ["default"] };
const capture = (options) => ({ identity: "mix-identity", ...options });

test("a complete direct example batch uses the Mix identity exporter and exact scope", () => {
  assert.deepEqual(directEnvelope(["parity.spec.mjs", "--project", "chromium"],
    { PREVIEW_COMPONENTS: "button", PREVIEW_EXAMPLES: "sizes,default" }, capture, index),
  { identity: "mix-identity", name: "button", layer: "parity", previewKey: "button", examples: ["default", "sizes"] });
  assert.equal(directEnvelope(["--project", "pixel"], { PREVIEW_COMPONENT: "shadcn-message" }, capture, index).name, "message");
  assert.equal(directEnvelope(["accessibility.spec.mjs"], { PREVIEW_COMPONENT: "button" }, capture, index).layer, "accessibility");
});

test("partial test filters and mixed-scope commands cannot produce importable metadata", () => {
  for (const args of [["parity.spec.mjs", "--grep", "default"], ["--project", "pixel", "--shard=1/2"], []]) {
    const meta = directEnvelope(args, { PREVIEW_COMPONENT: "button" }, () => { throw new Error("must not export"); }, index);
    assert.equal(meta.completed, false);
  }
  assert.equal(directEnvelope(["parity.spec.mjs"], { PREVIEW_COMPONENTS: "button,dialog" }, capture, index).completed, false);
});

test("unknown examples and components are rejected before executing a scoped run", () => {
  assert.throws(() => directEnvelope(["parity.spec.mjs"], { PREVIEW_COMPONENT: "button", PREVIEW_EXAMPLE: "unknown" }, capture, index), /unknown preview example/);
  assert.throws(() => directEnvelope(["parity.spec.mjs"], { PREVIEW_COMPONENT: "unknown" }, capture, index), /unknown preview component/);
});
