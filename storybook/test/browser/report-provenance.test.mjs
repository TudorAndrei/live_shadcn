import assert from "node:assert/strict";
import test from "node:test";
import { beginStateCoverage, completedEnvelope } from "./report-provenance.mjs";

const meta = { version: 2, source: "shadcn", name: "button", layer: "parity", preview_key: "button", examples: ["default"], identity: "test-time", completed: true };
const reportFor = (annotations, status = "passed") => ({
  errors: [],
  suites: [{ specs: [{ title: "button / default draws what React draws", tests: [{ annotations, results: [{ status }] }] }] }],
});

test("records expected states before visiting them and only completed states after visiting", () => {
  const info = { annotations: [] };
  const coverage = beginStateCoverage(info, "button.default", ["initial", "open"]);
  assert.deepEqual(JSON.parse(info.annotations[0].description), { example: "button.default", expected: ["initial", "open"], completed: [] });
  coverage.complete("initial");
  assert.equal(completedEnvelope(reportFor(info.annotations), meta, { code: 0 }).completed, false);
  coverage.complete("open");
  const actual = completedEnvelope(reportFor(info.annotations), meta, { code: 0 });
  assert.equal(actual.completed, true);
  assert.equal(actual.identity, "test-time");
  assert.deepEqual(actual.states["button.default"], { expected: ["initial", "open"], completed: ["initial", "open"] });
});

test("caller claims cannot turn missing, skipped, interrupted, or globally failed execution into completion", () => {
  for (const status of ["skipped", "interrupted", "timedOut"]) {
    assert.equal(completedEnvelope(reportFor([], status), meta, { code: 0 }).completed, false);
  }
  assert.equal(completedEnvelope(reportFor([]), meta, { code: 0 }).completed, false);
  const info = { annotations: [] };
  beginStateCoverage(info, "button.default", ["initial"]).complete("initial");
  const report = reportFor(info.annotations);
  assert.equal(completedEnvelope(report, meta, { code: null, signal: "SIGTERM" }).completed, false);
  assert.equal(completedEnvelope({ ...report, errors: [{ message: "global failure" }] }, meta, { code: 1 }).completed, false);
});

test("an executed assertion failure retains complete coverage but not a passing test result", () => {
  const info = { annotations: [] };
  beginStateCoverage(info, "button.default", ["initial"]).complete("initial");
  const report = reportFor(info.annotations, "failed");
  assert.equal(completedEnvelope(report, meta, { code: 1 }).completed, true);
  assert.equal(report.suites[0].specs[0].tests[0].results[0].status, "failed");
});
