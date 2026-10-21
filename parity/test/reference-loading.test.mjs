import assert from "node:assert/strict";
import test from "node:test";
import { createServer } from "vite";
import { loadReferenceExample } from "../src/reference-loader.mjs";

test("Vite resolves the pinned cn import in server and browser modules", async () => {
  const entry = "\0cn-test";
  const server = await createServer({
    server: { middlewareMode: true, watch: null },
    optimizeDeps: { noDiscovery: true, include: [] },
    logLevel: "silent",
    plugins: [{
      name: "cn-test",
      resolveId: id => id === entry ? entry : undefined,
      load: id => id === entry ? 'export { cn } from "cn";' : undefined,
    }],
  });
  try {
    const { cn } = await server.ssrLoadModule(entry);
    assert.equal(cn("p-2", false, ["p-4", "block"]), "p-4 block");
    const transformed = await server.transformRequest(entry);
    assert.match(transformed.code, /\/node_modules\/(?:\.vite\/deps\/cn\.js|cn\/)/);
  } finally {
    await server.close();
  }
});

test("a route loads only its selected official example", async () => {
  const loaded = [];
  const Example = () => null;
  const officialExamples = Object.fromEntries(Array.from({ length: 462 }, (_, index) => [
    `alert.example-${index}`, async () => { loaded.push(index); return Example; },
  ]));
  const result = await loadReferenceExample("/preview/alert/example-42", {
    officialComponents: new Set(["alert"]), officialExamples, examples: {},
  });
  assert.equal(result, Example);
  assert.deepEqual(loaded, [42]);
});

test("local examples load on request and official routes require official examples", async () => {
  const Example = () => null;
  const catalog = {
    officialComponents: new Set(["alert"]), officialExamples: {},
    examples: { "local.default": async () => Example, "alert.default": async () => Example },
  };
  assert.equal(await loadReferenceExample("/preview/local/default", catalog), Example);
  assert.equal(await loadReferenceExample("/preview/alert/default", catalog), undefined);
});
