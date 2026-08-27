import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
// The copy `upstream.mjs` makes, not `registry/upstream/` itself. See that file
// for why the sources have to live inside this tree to resolve at all.
const upstream = resolve(here, "src/upstream");

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
  plugins: [react()],
  resolve: {
    alias: [
      // Two files upstream imports and shadcn's registry does not publish: the
      // `cn` helper every class string is built with, and a hook that reports
      // the viewport width. Both are reimplemented in `src/shim`, and both are
      // small enough that reimplementing them is not a guess.
      { find: "@/registry/bases/base/lib/utils", replacement: resolve(here, "src/shim/utils.ts") },
      { find: "@repo/shadcn-ui/lib/utils", replacement: resolve(here, "src/shim/utils.ts") },
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
      { find: "@/registry/bases/base/ui", replacement: resolve(upstream, "shadcn/ui") },
      { find: "@repo/shadcn-ui/components/ui", replacement: resolve(upstream, "shadcn/ui") },
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
