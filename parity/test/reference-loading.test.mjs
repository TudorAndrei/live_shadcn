import assert from "node:assert/strict";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import * as tabler from "@tabler/icons-react";
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

test("named Tabler imports preserve pinned SVGs with a bounded browser module graph", async (t) => {
  const entry = fileURLToPath(new URL("./tabler-reference-fixture.tsx", import.meta.url));
  const server = await createServer({
    server: { middlewareMode: true, watch: null },
    optimizeDeps: { noDiscovery: true, include: [] },
    logLevel: "silent",
    plugins: [{
      name: "tabler-reference-test",
      resolveId: id => id === entry ? entry : undefined,
      load: id => id === entry ? `
        import type { Icon, IconProps, IconMoon } from "@tabler/icons-react";
        import {
          IconCheck, IconCopy as Copy, IconInfoCircle, IconStar,
          IconCodeAsterisk,
          Icon123, IconNumber123, type IconProps as Props,
          type IconAlarm as AlarmType,
        } from "@tabler/icons-react";
        import { IconCodeAsterix as Asterisk } from '@tabler/icons-react';
        export { IconCheck, Copy, IconInfoCircle, IconStar, Asterisk,
          IconCodeAsterisk, Icon123, IconNumber123 };
        const props: Props & IconProps = { size: 18, stroke: 1.5, title: "Copy" };
        export function Preview() { return <Copy {...props} />; }
      ` : undefined,
    }],
  });
  try {
    const icons = await server.ssrLoadModule(entry);
    const props = { size: 18, stroke: 1.5, title: "Copy" };
    for (const [local, exported] of [
      ["IconCheck", "IconCheck"], ["Copy", "IconCopy"],
      ["IconInfoCircle", "IconInfoCircle"], ["IconStar", "IconStar"],
      ["Asterisk", "IconCodeAsterix"], ["IconCodeAsterisk", "IconCodeAsterisk"],
      ["Icon123", "Icon123"], ["IconNumber123", "IconNumber123"],
    ]) {
      assert.equal(
        renderToStaticMarkup(createElement(icons[local], props)),
        renderToStaticMarkup(createElement(tabler[exported], props)),
        `${local} must render the pinned ${exported} SVG`,
      );
    }
    assert.equal(icons.Asterisk, icons.IconCodeAsterisk);
    assert.equal(icons.Icon123, icons.IconNumber123);
    assert.equal(
      renderToStaticMarkup(createElement(icons.Preview)),
      renderToStaticMarkup(createElement(tabler.IconCopy, props)),
    );

    await server.transformRequest(entry);
    const graph = server.environments.client.moduleGraph;
    const pending = [...graph.getModuleById(entry).importedModules];
    const tablerModules = new Set();
    while (pending.length) {
      const module = pending.shift();
      if (!module.id.includes("/@tabler/icons-react/") || tablerModules.has(module.id)) continue;
      tablerModules.add(module.id);
      assert.ok(tablerModules.size <= 8, "six requested icons need at most two shared Tabler modules");
      await server.transformRequest(module.url);
      pending.push(...module.importedModules);
      assert.ok(pending.length <= 16, `Tabler module ${module.id} exceeds the import graph budget: ${pending.length}`);
    }
    assert.ok(tablerModules.size >= 6, "the six distinct requested icon modules must resolve");
    t.diagnostic(`Browser graph contains ${tablerModules.size} Tabler modules`);
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
