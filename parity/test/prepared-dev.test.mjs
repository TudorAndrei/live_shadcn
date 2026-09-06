import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const packageJson = new URL("../package.json", import.meta.url);
const { serverPolicy } = await import("../../storybook/test/browser/server-policy.mjs");

test("the prepared parity server only starts Vite", () => {
  const scripts = JSON.parse(readFileSync(packageJson, "utf8")).scripts;

  assert.equal(scripts.dev, "npm run upstream && vite");
  assert.equal(scripts["dev:prepared"], "vite");
});

test("only a verifier-managed run reuses prepared servers", () => {
  assert.deepEqual(serverPolicy({ LIVE_SHADCN_MANAGED_SERVERS: "1" }), {
    parityCommand: "npm run dev:prepared",
    reuseExistingServer: true,
  });

  assert.deepEqual(serverPolicy({ PARITY_PREPARED: "1" }), {
    parityCommand: "npm run dev:prepared",
    reuseExistingServer: false,
  });

  assert.deepEqual(serverPolicy({}), {
    parityCommand: "npm run dev",
    reuseExistingServer: false,
  });

  assert.deepEqual(serverPolicy({ CI: "true" }), {
    parityCommand: "npm run dev",
    reuseExistingServer: false,
  });
});
