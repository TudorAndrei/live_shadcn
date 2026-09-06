import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const source = (path) => readFileSync(new URL(path, import.meta.url), "utf8");

test("the pinned React reference pre-renders preview routes before hydration", () => {
  const entry = source("../src/main.tsx");
  const server = source("../src/reference-server.tsx");
  const config = source("../vite.config.mjs");

  assert.match(entry, /hydrateRoot\(/);
  assert.doesNotMatch(entry, /createRoot\(/);
  assert.match(server, /renderToString\(/);
  assert.match(config, /ssrLoadModule\("\/src\/reference-server\.tsx"\)/);
  assert.match(config, /pathname\.startsWith\("\/preview\/"\)/);
});
