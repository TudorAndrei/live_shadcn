// Copies the fetched upstream sources into this application's tree.
//
// Node resolves a bare import by walking up from the file that wrote it. The
// sources live in `registry/upstream/`, which has no `node_modules` above it
// and never should — it holds what `mix ui.fetch` downloaded and nothing else.
// So `import { Accordion } from "@base-ui/react/accordion"` inside a fetched
// file resolves to nothing at all.
//
// `storybook/assets/upstream.mjs` copies the style sheets in for the same
// reason, in the same direction, and the copies are gitignored in both places:
// the originals are the record, and `mix ui.fetch` owns them.

import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const from = resolve(here, "../registry/upstream");
const to = join(here, "src/upstream");

await rm(to, { force: true, recursive: true });
await mkdir(to, { recursive: true });

for (const directory of ["shadcn", "ai_elements"]) {
  await cp(join(from, directory), join(to, directory), {
    recursive: true,
    // The style sheets are the storybook's business, and copying 600 KB of CSS
    // into a source tree Tailwind scans would have it read every rule as a
    // class name.
    filter: (path) => !path.includes(`${directory}/styles`) && !path.includes(`${directory}/theme`),
  });
}

console.log(`copied upstream sources to ${to}`);
