import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const [reportPath, planPath, cachePath] = process.argv.slice(2);
assert.ok(reportPath && planPath && cachePath, "provide REPORT PLAN CACHE");
const read = path => JSON.parse(readFileSync(path, "utf8"));
const report = read(reportPath);
const plan = read(planPath);
const cache = read(cachePath);
const sorted = values => [...values].sort();
const passed = sorted(Object.keys(report.results).filter(key => report.results[key].pass === true));
const failed = sorted(Object.keys(report.results).filter(key => report.results[key].pass !== true));

assert.deepEqual(sorted(Object.keys(report.results)), sorted(report.components), "report scope is incomplete");
assert.deepEqual(sorted(plan.components), sorted(report.components), "cache plan changed the assigned scope");
assert.deepEqual(sorted([...plan.reused, ...plan.run]), sorted(report.components), "cache plan lost or repeated a component");
assert.equal(cache.version, 1, "unknown result cache version");
assert.deepEqual(sorted(Object.keys(cache.results)), passed, "fresh passed results were not saved, or failed results were retained");
for (const key of passed) {
  assert.deepEqual(cache.results[key], report.results[key], `cache changed the result for ${key}`);
}
assert.match(cache.runtime.utc_date, /^\d{4}-\d{2}-\d{2}$/, "cache has no UTC date");

if (cache.runtime.utc_date !== new Date().toISOString().slice(0, 10)) {
  console.log("The UTC date changed. Saved results require fresh checks.");
} else {
  assert.deepEqual(sorted(plan.reused), passed, "saved passed results are not reusable");
  assert.deepEqual(sorted(plan.run), failed, "cache plan does not rerun exactly the failed components");
  assert.equal(plan.browser_needed, failed.length > 0, "cache plan has the wrong browser requirement");
  console.log(`Confirmed reuse of ${passed.length} passed component results.`);
}
