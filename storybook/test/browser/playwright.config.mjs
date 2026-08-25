import { defineConfig, devices } from "@playwright/test";

import { ours } from "./servers.mjs";

// The demo application is the fixture. `mix ui.verify` runs this config, and a
// developer can run `npm run verify` here directly against the same pages.
const PORT = process.env.STORYBOOK_PORT || "4101";

// The React reference `parity.spec.mjs` compares against. It renders the same
// upstream sources the specs were read from, so a difference between the two
// pages is a difference between the generated component and upstream.
const PARITY_PORT = process.env.PARITY_PORT || "4102";

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
  testMatch: /.*\.spec\.mjs/,
  // One worker, on purpose. Every test drives the same development server, and
  // a verification run that is flaky under load verifies nothing.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["list"], ["json", { outputFile: "results.json" }]] : "list",
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    parityURL: `http://127.0.0.1:${PARITY_PORT}`,
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: [
    {
      command: "mix phx.server",
      cwd: "../..",
      url: `http://127.0.0.1:${PORT}`,
      env: { PORT, MIX_ENV: "dev" },
      reuseExistingServer: !process.env.CI,
      stdout: "pipe",
      stderr: "pipe",
      timeout: 120_000,
    },
    {
      command: "npm run dev",
      cwd: "../../../parity",
      url: `http://127.0.0.1:${PARITY_PORT}`,
      reuseExistingServer: !process.env.CI,
      stdout: "pipe",
      stderr: "pipe",
      timeout: 120_000,
    },
  ],
});
