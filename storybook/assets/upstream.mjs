// Copies the shadcn styling layer from registry/upstream into the asset
// pipeline, unchanged.
//
// The copy is not cosmetic. shadcn's own `globals.css` opens with
// `@import "tailwindcss"` and `@import "shadcn/tailwind.css"`, and Tailwind
// resolves a bare import from the directory of the file that wrote it. Left in
// registry/upstream, which has no node_modules above it, those imports do not
// resolve; copied here, they resolve exactly as they do upstream.
//
// Everything it copies is gitignored on both sides. `mix ui.fetch` is what puts
// the sources there, and this script says so rather than failing obscurely.

import { cpSync, existsSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const upstream = join(here, "..", "..", "registry", "upstream", "shadcn");
const target = join(here, "css", "upstream");

const sources = [
  ["theme", "the design tokens every rule resolves against"],
  ["styles", "the cn- rules themselves"],
];

const missing = sources.filter(([dir]) => !existsSync(join(upstream, dir)));

if (missing.length > 0) {
  const names = missing.map(([dir]) => `registry/upstream/shadcn/${dir}`).join(", ");
  console.error(`\nMissing ${names}.\n\nRun \`mix ui.fetch\` in tools/ first.\n`);
  process.exit(1);
}

rmSync(target, { recursive: true, force: true });
mkdirSync(target, { recursive: true });

for (const [dir] of sources) {
  cpSync(join(upstream, dir), join(target, dir), { recursive: true });
}
