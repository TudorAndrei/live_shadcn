import { defineConfig, devices } from "@playwright/test";

import { pixelChromiumArgs } from "./chromium-resource-policy.mjs";
import { ours } from "./servers.mjs";
import { verificationSpecFiles } from "./registries.mjs";
import { assertVerificationInvocation, serverPolicy } from "./server-policy.mjs";

// The demo application is the fixture. `mix ui.verify` runs this config, and a
// developer can run `npm run verify` here directly against the same pages.
const PORT = process.env.STORYBOOK_PORT || "4101";

// The React reference `parity.spec.mjs` compares against. It renders the same
// upstream sources the specs were read from, so a difference between the two
// pages is a difference between the reviewed port and upstream. `mix ui.verify`
// prepares those sources once before it starts these servers.
const PARITY_PORT = process.env.PARITY_PORT || "4102";

// This is private to `mix ui.verify`. It starts both servers after it prepares
// the exact upstream source tree, then each short Playwright batch may use that
// pair. A direct Playwright invocation starts and owns a new pair instead.
const SERVER_POLICY = serverPolicy();

assertVerificationInvocation();

// Refuse a server that is not ours before a single test runs.
//
// `reuseExistingServer` means Playwright takes whatever is already listening.
// An unrelated container answering 401 on 4101 was taken for the storybook, and
// every parity test then reported its component as *missing* rather than as
// different — which reads exactly like a harness that ran and found nothing
// wrong. A check that cannot tell "did not run" from "passed" is worse than no
// check.
//
// So each port is probed for a page only that server serves. This runs once, in
// the config, so the failure names the port rather than arriving as sixty
// confusing test failures.
await ours({
  storybook: { port: PORT, path: "/previews.json", expect: /"accordion"/ },
  parity: { port: PARITY_PORT, path: "/preview/badge/variants", expect: /<div id="root"/ },
});

export default defineConfig({
  testDir: ".",
  testMatch: verificationSpecFiles,
  // One worker, on purpose. Every test drives the same development server, and
  // a verification run that is flaky under load verifies nothing.
  fullyParallel: false,
  workers: 1,
  forbidOnly: true,
  retries: process.env.CI ? 1 : 0,
  reporter:
    process.env.LIVE_SHADCN_VERIFY_ENVELOPE || process.env.CI
      ? [["list"], ["json", { outputFile: "results.json" }]]
      : "list",
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    parityURL: `http://127.0.0.1:${PARITY_PORT}`,
    // Date Picker sources use `new Date()` while the LiveView uses
    // `Date.utc_today()`. Keep both pages on the same calendar date at the
    // local midnight boundary.
    timezoneId: "UTC",
    trace: "retain-on-failure",
  },
  projects: [
    { name: "chromium", testIgnore: /pixel\.spec\.mjs/, use: { ...devices["Desktop Chrome"] } },

    // A project of its own, so the knobs a photograph needs never leak into the
    // behaviour specs. Both sides are shot in this one browser on this one
    // machine, so what these settings buy is not portability — it is that two
    // loads within a single run rasterise identically, and that a retry
    // reproduces the same pixels rather than flipping a verdict.
    {
      name: "pixel",
      testMatch: /pixel\.spec\.mjs/,
      use: {
        ...devices["Desktop Chrome"],
        // Headed and headless rasterise differently. Never photograph headed.
        headless: true,
        deviceScaleFactor: 2,
        colorScheme: "light",
        timezoneId: "UTC",
        locale: "en-US",
        reducedMotion: "reduce",
        // Pixel failures already attach both renders and the exact diff. A
        // Playwright trace records more screenshots and DOM snapshots for the
        // same work, which adds memory, CPU, and disk use without new evidence.
        trace: "off",
        launchOptions: {
          args: pixelChromiumArgs,
        },
      },
    },
  ],
  webServer: [
    {
      command: "mix phx.server",
      cwd: "../..",
      url: `http://127.0.0.1:${PORT}`,
      env: { PORT, MIX_ENV: "dev" },
      reuseExistingServer: SERVER_POLICY.reuseExistingServer,
      stdout: "pipe",
      stderr: "pipe",
      timeout: 120_000,
    },
    {
      command: SERVER_POLICY.parityCommand,
      cwd: "../../../parity",
      url: `http://127.0.0.1:${PARITY_PORT}`,
      // A managed verifier starts Vite only after it prepares the pinned
      // sources. No other process may be reused: it could serve an old tree.
      reuseExistingServer: SERVER_POLICY.reuseExistingServer,
      stdout: "pipe",
      stderr: "pipe",
      timeout: 120_000,
    },
  ],
});
