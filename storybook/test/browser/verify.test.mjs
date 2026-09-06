import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { embedVerificationReport, runVerification } from "./verify.mjs";

test("the verification wrapper forwards all arguments and the source lease environment", async () => {
  const calls = [];
  const lease = { token: "lease-token" };

  const result = await runVerification({
    arguments: ["--project", "pixel", "--grep", "calendar / range"],
    environment: { CI: "true", PREVIEW_COMPONENT: "calendar" },
    leasePath: "/tmp/source-lease",
    acquire: async (path) => {
      calls.push(["acquire", path]);
      return lease;
    },
    release: async (path, released) => calls.push(["release", path, released]),
    execute: async (options) => {
      calls.push(["execute", options]);
      return { code: 0, signal: null };
    },
  });

  assert.deepEqual(result, { code: 0, signal: null });
  assert.deepEqual(calls[0], ["acquire", "/tmp/source-lease"]);
  assert.deepEqual(calls[1][1].arguments, ["--project", "pixel", "--grep", "calendar / range"]);
  assert.equal(calls[1][1].environment.CI, "true");
  assert.equal(calls[1][1].environment.PREVIEW_COMPONENT, "calendar");
  assert.equal(calls[1][1].environment.PARITY_SOURCE_LEASE_TOKEN, "lease-token");
  assert.equal(calls[1][1].environment.LIVE_SHADCN_BROWSER_VERIFY_WRAPPER, "1");
  assert.deepEqual(calls[2], ["release", "/tmp/source-lease", lease]);
});

test("the verification wrapper releases the source lease when Playwright fails", async () => {
  const lease = { token: "lease-token" };
  const released = [];

  await assert.rejects(
    runVerification({
      leasePath: "/tmp/source-lease",
      acquire: async () => lease,
      release: async (path, value) => released.push([path, value]),
      execute: async () => {
        throw new Error("Playwright could not start");
      },
    }),
    /Playwright could not start/,
  );

  assert.deepEqual(released, [["/tmp/source-lease", lease]]);
});

test("embedVerificationReport writes verification metadata into the Playwright JSON report", () => {
  const directory = mkdtempSync(join(tmpdir(), "live-shadcn-verify-"));
  const reportPath = join(directory, "results.json");
  const envelope = {
    version: 1,
    source: "shadcn",
    name: "button",
    layer: "parity",
    preview_key: "button",
    examples: ["default"],
    states: [],
    identity: "digest-1",
    completed: true,
  };

  writeFileSync(reportPath, `${JSON.stringify({ suites: [], errors: [] })}\n`);

  const previous = process.env.LIVE_SHADCN_VERIFY_ENVELOPE;
  const previousOutput = process.env.PLAYWRIGHT_JSON_OUTPUT_FILE;

  process.env.LIVE_SHADCN_VERIFY_ENVELOPE = JSON.stringify(envelope);
  process.env.PLAYWRIGHT_JSON_OUTPUT_FILE = reportPath;

  try {
    embedVerificationReport(reportPath);

    const report = JSON.parse(readFileSync(reportPath, "utf8"));
    assert.deepEqual(report._live_shadcn_verification, envelope);
  } finally {
    if (previous === undefined) {
      delete process.env.LIVE_SHADCN_VERIFY_ENVELOPE;
    } else {
      process.env.LIVE_SHADCN_VERIFY_ENVELOPE = previous;
    }

    if (previousOutput === undefined) {
      delete process.env.PLAYWRIGHT_JSON_OUTPUT_FILE;
    } else {
      process.env.PLAYWRIGHT_JSON_OUTPUT_FILE = previousOutput;
    }

    rmSync(directory, { recursive: true, force: true });
  }
});
