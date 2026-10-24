import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

function check(change = () => {}) {
  const report = { components: ["shadcn/button", "shadcn/dialog"],
    results: { "shadcn/button": { pass: true }, "shadcn/dialog": { pass: false } } };
  const plan = { components: report.components, reused: ["shadcn/button"],
    run: ["shadcn/dialog"], browser_needed: true };
  const cache = { version: 1, runtime: { utc_date: new Date().toISOString().slice(0, 10) },
    results: { "shadcn/button": structuredClone(report.results["shadcn/button"]) } };
  change(report, plan, cache);
  const folder = mkdtempSync(join(tmpdir(), "cache-publication-"));
  const paths = [report, plan, cache].map((data, index) => {
    const path = join(folder, `${index}.json`);
    writeFileSync(path, JSON.stringify(data));
    return path;
  });
  try {
    return spawnSync(process.execPath, [new URL("check-cache-plan.mjs", import.meta.url).pathname, ...paths],
      { encoding: "utf8" });
  } finally {
    rmSync(folder, { recursive: true, force: true });
  }
}

test("a fresh pass remains reusable after another component fails", () => {
  const result = check();
  assert.equal(result.status, 0, result.stderr);
});

test("missing fresh passes, retained failures, and wrong scope fail the publication check", () => {
  for (const change of [
    (_r, _p, c) => { c.results = {}; },
    (_r, _p, c) => { c.results["shadcn/button"].evidence = "different result"; },
    (r, _p, c) => { c.results["shadcn/dialog"] = r.results["shadcn/dialog"]; },
    (_r, p) => { p.reused = []; p.run = p.components; },
    (_r, p) => { p.reused.push("shadcn/button"); },
    (_r, p) => { p.browser_needed = false; },
    (_r, p) => { p.components = ["shadcn/button"]; },
  ]) assert.notEqual(check(change).status, 0);
});

test("a UTC date change expires reuse while still requiring every fresh pass to be saved", () => {
  const result = check((_r, p, c) => {
    c.runtime.utc_date = "2000-01-01";
    p.reused = [];
    p.run = p.components;
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /UTC date changed/);
});
