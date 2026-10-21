import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, readFileSync, rmSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

const matrix = { include: [
  { shard: "1/2", components: ["shadcn/button"] },
  { shard: "2/2", components: ["shadcn/data-table"] },
] };
const record = { pass: true, evidence: "current-test-identity", checks: {} };
const reports = matrix.include.map(({ shard, components }) => ({
  source: "shadcn", shard, components,
  results: Object.fromEntries(components.map((key) => [key, record])),
}));

function run(input, plan = matrix) {
  const root = mkdtempSync(join(tmpdir(), "verification-merge-"));
  const directory = join(root, "reports");
  const output = join(root, "VERIFY.json");
  mkdirSync(directory);
  const original = { "ai_elements/message": { pass: false, evidence: "keep-this-record" } };
  writeFileSync(output, JSON.stringify(original));
  input.forEach((report, index) => writeFileSync(join(directory, `${index}.json`), JSON.stringify(report)));
  try {
    const process_ = spawnSync(process.execPath, [new URL("merge-verification.mjs", import.meta.url).pathname, directory, output], {
      env: { ...process.env, VERIFICATION_MATRIX: JSON.stringify(plan) }, encoding: "utf8",
    });
    return { ...process_, saved: JSON.parse(readFileSync(output, "utf8")), original };
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test("the CI merge publishes all assigned records and preserves the other source", () => {
  const result = run(reports);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.saved, { ...result.original, "shadcn/button": record, "shadcn/data-table": record });
});

test("AI Elements uses the same complete-scope transport", () => {
  const plan = { include: [{ shard: "1/1", components: ["ai_elements/code-block"] }] };
  const result = run([{ source: "ai_elements", shard: "1/1", components: ["ai_elements/code-block"],
    results: { "ai_elements/code-block": record } }], plan);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.saved, { ...result.original, "ai_elements/code-block": record });
});

test("incomplete, duplicated, wrong-scope, or failed shard reports cannot change the saved records", () => {
  for (const input of [
    [reports[0]],
    [reports[0], reports[0]],
    [reports[0], { ...reports[1], results: { "shadcn/dialog": record } }],
    [reports[0], { ...reports[1], results: { "shadcn/data-table": { ...record, pass: false } } }],
  ]) {
    const result = run(input);
    assert.notEqual(result.status, 0);
    assert.deepEqual(result.saved, result.original);
  }
});
