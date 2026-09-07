import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { createServer } from "vite";

const source = (path) => readFileSync(new URL(path, import.meta.url), "utf8");

test("preview HTTP routes await server rendering before the Vite fallback", async () => {
  const server = await createServer({
    server: { port: 0, watch: null },
    logLevel: "silent",
    plugins: [{
      name: "preview-render-fixture",
      enforce: "pre",
      load(id) {
        if (id.endsWith("/src/reference-server.tsx")) {
          return 'export async function renderReferencePreview(url) { return `<div data-preview="fixture">${url}</div>`; }';
        }
      },
    }],
  });
  try {
    await server.listen();
    const { port } = server.httpServer.address();
    const response = await fetch(`http://127.0.0.1:${port}/preview/fixture/default?test=1`);
    assert.equal(response.status, 200);
    const html = await response.text();
    assert.match(html, /<div id="root"><div data-preview="fixture">\/preview\/fixture\/default\?test=1<\/div><\/div>/);
  } finally {
    await server.close();
  }
});

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
