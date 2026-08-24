import { defineConfig, devices } from "@playwright/test";

// The demo application is the fixture. `mix ui.verify` runs this config, and a
// developer can run `npm run verify` here directly against the same pages.
const PORT = process.env.STORYBOOK_PORT || "4101";

// The React reference `parity.spec.mjs` compares against. It renders the same
// upstream sources the specs were read from, so a difference between the two
// pages is a difference between the generated component and upstream.
const PARITY_PORT = process.env.PARITY_PORT || "4102";

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
