import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
// The copy `upstream.mjs` makes, not `registry/upstream/` itself. See that file
// for why the sources have to live inside this tree to resolve at all.
const upstream = resolve(here, "src/upstream");

function referenceSsr() {
  return {
    name: "reference-ssr",
    configureServer(server) {
      // Install before Vite rewrites preview URLs to index.html.
      server.middlewares.use(async (request, response, next) => {
        const requestUrl = request.url || "/";
        const { pathname } = new URL(requestUrl, "http://127.0.0.1");

        if (!pathname.startsWith("/preview/")) {
          next();
          return;
        }

        try {
          const { renderReferencePreview } = await server.ssrLoadModule("/src/reference-server.tsx");
          const app = await renderReferencePreview(requestUrl);
          const template = `<!doctype html>
<html lang="en" class="style-vega" data-reference-page>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>live_shadcn parity</title>
  </head>
  <body class="bg-background text-foreground antialiased">
    <main class="mx-auto max-w-3xl px-6 py-12">
      <div id="root">${app}</div>
    </main>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>`;
          const html = await server.transformIndexHtml(pathname, template);

          response.statusCode = 200;
          response.setHeader("Content-Type", "text/html");
          response.end(html);
        } catch (error) {
          server.ssrFixStacktrace(error);
          next(error);
        }
      });
    },
  };
}

// The aliases upstream writes its imports against. shadcn builds inside a Next
// application and AI Elements inside a monorepo, so each names the other's
// files through a prefix its own build resolves. Both point at what
// `mix ui.fetch` downloaded, which is the whole reason this application can
// exist: the sources are already here, at the commit registry/UPSTREAM.json
// pins.
//
// Longest prefix first. Vite tries them in order, and `@/registry` would
// swallow `@/registry/bases/base/lib/utils` before the shim below could.
export default defineConfig({
  root: here,
  plugins: [react(), referenceSsr()],
  resolve: {
    alias: [
      { find: /^cn$/, replacement: resolve(here, "src/shim/utils.ts") },
      { find: "next/image", replacement: resolve(here, "src/shim/next-image.tsx") },
      { find: "next/link", replacement: resolve(here, "src/shim/next-link.tsx") },
      { find: "next/font/google", replacement: resolve(here, "src/shim/next-font-google.ts") },
      { find: "@shadcn/helpers", replacement: resolve(upstream, "shadcn_helpers") },
      // Two files upstream imports and shadcn's registry does not publish: the
      // `cn` helper every class string is built with, and a hook that reports
      // the viewport width. Both are reimplemented in `src/shim`, and both are
      // small enough that reimplementing them is not a guess.
      { find: "@/registry/bases/base/lib/utils", replacement: resolve(here, "src/shim/utils.ts") },
      { find: "@repo/shadcn-ui/lib", replacement: resolve(upstream, "ai_shadcn/lib") },
      { find: "@repo/shadcn-ui/hooks", replacement: resolve(upstream, "ai_shadcn/hooks") },
      {
        find: "@/registry/bases/base/hooks/use-mobile",
        replacement: resolve(here, "src/shim/use-mobile.ts"),
      },
      // shadcn renders a placeholder where a caller passes an icon. It lives in
      // the documentation site rather than in the registry, so it is not
      // fetched.
      {
        find: "@/app/(create)/components/icon-placeholder",
        replacement: resolve(here, "src/shim/icon-placeholder.tsx"),
      },
      // The markdown renderer, which the reviewed ports do not have: the
      // pipeline emits a seam and the application chooses what sits behind it.
      // Rendering Streamdown here would compare two markdown renderers, and
      // neither of them is the component. See `src/shim/streamdown.tsx`.
      { find: /^@streamdown\/.*/, replacement: resolve(here, "src/shim/streamdown-plugin.ts") },
      { find: "streamdown", replacement: resolve(here, "src/shim/streamdown.tsx") },
      {
        find: "@/registry/new-york-v4",
        replacement: resolve(upstream, "shadcn_new_york_v4"),
      },
      { find: "@/registry/bases/base/ui", replacement: resolve(upstream, "shadcn/ui") },
      { find: "@/registry/icons", replacement: resolve(upstream, "shadcn_icons") },
      { find: "@/components", replacement: resolve(upstream, "shadcn_app_components") },
      { find: "@/hooks", replacement: resolve(upstream, "shadcn_app_hooks") },
      { find: "@/lib", replacement: resolve(upstream, "shadcn_app_lib") },
      { find: "@/styles/base-nova/ui", replacement: resolve(upstream, "shadcn/ui") },
      {
        find: /^@\/styles\/[^/]+\/ui(?:-rtl)?/,
        replacement: resolve(upstream, "shadcn/ui"),
      },
      {
        find: "@repo/shadcn-ui/components/ui",
        replacement: resolve(upstream, "ai_shadcn/components/ui"),
      },
      { find: "@repo/elements", replacement: resolve(upstream, "ai_elements") },
      { find: "@/registry/bases/base", replacement: resolve(upstream, "shadcn") },
      // What the examples in this application import. The three above are the
      // prefixes upstream writes for itself; this one says out loud that an
      // example renders a fetched source and nothing else.
      { find: "@upstream", replacement: upstream },
    ],
  },
  server: {
    host: "127.0.0.1",
    port: Number(process.env.PARITY_PORT || 4102),
    strictPort: true,
    // One style sheet serves both renderers, and it is built by the storybook.
    // See `src/main.tsx`.
    fs: { allow: [repo] },
  },
});
