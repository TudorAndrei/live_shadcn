import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { embedVerificationReport, runVerification } from "./verify.mjs";
import { acquireSourceLease, releaseSourceLease } from "../../../parity/source-lease.mjs";

test("a scoped direct batch captures identity before executing and always requests a report", async () => {
  const calls = [];
  const meta = { version: 2, identity: "captured-before-browser", layer: "parity", completed: true };
  await runVerification({
    arguments: ["parity.spec.mjs"],
    environment: { PREVIEW_COMPONENTS: "button", PREVIEW_EXAMPLES: "default" },
    acquire: async () => ({ token: "test" }),
    release: async () => {},
    prepareEnvelope: (args, env) => {
      calls.push("identity");
      assert.deepEqual(args, ["parity.spec.mjs"]);
      assert.equal(env.PREVIEW_COMPONENTS, "button");
      return meta;
    },
    execute: async ({ environment }) => {
      calls.push("execute");
      assert.equal(environment.LIVE_SHADCN_VERIFY_ENVELOPE, JSON.stringify(meta));
      assert.ok(environment.PLAYWRIGHT_JSON_OUTPUT_FILE);
      return { code: 0, signal: null };
    },
  });
  assert.deepEqual(calls, ["identity", "execute"]);
});

test("a browser batch uses and returns its live parent lease", async () => {
  const directory = mkdtempSync(join(tmpdir(), "verify-parent-"));
  const leasePath = join(directory, "lease");
  const parent = await acquireSourceLease(leasePath);
  const ownerPath = join(leasePath, "owner.json");
  const before = readFileSync(ownerPath, "utf8");
  try {
    const outcome = await runVerification({
      leasePath,
      environment: { PARITY_SOURCE_LEASE_TOKEN: parent.token, LIVE_SHADCN_MANAGED_SERVERS: "1" },
      acquire: (path) => acquireSourceLease(path, { waitMs: 100 }),
      execute: async ({ environment }) => {
        const owner = JSON.parse(readFileSync(ownerPath, "utf8"));
        assert.equal(owner.token, parent.token);
        assert.equal(environment.PARITY_SOURCE_LEASE_TOKEN, parent.token);
        return { code: 0, signal: null };
      },
    });
    assert.equal(outcome.code, 0);
    assert.equal(readFileSync(ownerPath, "utf8"), before);
  } finally {
    await releaseSourceLease(leasePath, parent);
    rmSync(directory, { recursive: true, force: true });
  }
});

test("a child failure cannot publish a previous run as current evidence", async () => {
  const directory = mkdtempSync(join(tmpdir(), "verify-old-report-"));
  const reportPath = join(directory, "results.json");
  writeFileSync(reportPath, JSON.stringify({ suites: [{ title: "old passing result" }] }));
  try {
    const result = await runVerification({
      environment: {
        PLAYWRIGHT_JSON_OUTPUT_FILE: reportPath,
        LIVE_SHADCN_VERIFY_ENVELOPE: JSON.stringify({ identity: "current", completed: true }),
      },
      acquire: async () => ({ token: "test" }),
      release: async () => {},
      execute: async () => ({ code: 1, signal: null }),
    });
    assert.equal(result.code, 1);
    assert.equal(existsSync(reportPath), false);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("a fresh failure report keeps the current run identity and results", async () => {
  const directory = mkdtempSync(join(tmpdir(), "verify-fresh-report-"));
  const reportPath = join(directory, "results.json");
  const envelope = { identity: "current", completed: true };
  const suites = [{ title: "current test failure" }];
  try {
    await runVerification({
      environment: {
        PLAYWRIGHT_JSON_OUTPUT_FILE: reportPath,
        LIVE_SHADCN_VERIFY_ENVELOPE: JSON.stringify(envelope),
      },
      acquire: async () => ({ token: "test" }),
      release: async () => {},
      execute: async ({ environment }) => {
        writeFileSync(environment.PLAYWRIGHT_JSON_OUTPUT_FILE, JSON.stringify({ suites, errors: [] }));
        return { code: 1, signal: null };
      },
    });
    assert.deepEqual(JSON.parse(readFileSync(reportPath, "utf8")), {
      suites, errors: [], _live_shadcn_verification: { ...envelope, states: {}, completed: false },
    });
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

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

test("an AI Elements run retains its source filter through the browser command", async () => {
  let selectedSource;
  await runVerification({
    arguments: ["attachments.spec.mjs"],
    environment: { PREVIEW_SOURCE: "ai_elements" },
    acquire: async () => ({ token: "test" }),
    release: async () => {},
    execute: async ({ environment }) => {
      selectedSource = environment.PREVIEW_SOURCE;
      return { code: 0, signal: null };
    },
  });
  assert.equal(selectedSource, "ai_elements");
});

test("embedVerificationReport writes verification metadata into the Playwright JSON report", () => {
  const directory = mkdtempSync(join(tmpdir(), "live-shadcn-verify-"));
  const reportPath = join(directory, "results.json");
  const envelope = {
    version: 2,
    source: "shadcn",
    name: "button",
    layer: "parity",
    preview_key: "button",
    examples: ["default"],
    states: {},
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
    assert.deepEqual(report._live_shadcn_verification, { ...envelope, states: {}, completed: false });
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
