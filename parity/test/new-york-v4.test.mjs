import assert from "node:assert/strict";
import { dirname, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import config from "../vite.config.mjs";
import { pinnedSourceDirectories } from "../upstream-directories.mjs";

const here = dirname(fileURLToPath(import.meta.url));

test("copies the complete pinned New York v4 registry", () => {
  const manifest = {
    sources: {
      ai_elements: {
        dir: "elements",
        examples_dir: "examples",
        shadcn_dir: "shadcn",
      },
      shadcn: { dir: "apps/v4/registry/bases/base/ui" },
    },
  };

  const directories = pinnedSourceDirectories({
    ai: "/pinned/ai-elements",
    shadcn: "/pinned/shadcn-ui",
    manifest,
  });

  assert.equal(
    directories.shadcn_new_york_v4,
    "/pinned/shadcn-ui/apps/v4/registry/new-york-v4",
  );
  assert.equal(directories.shadcn, "/pinned/shadcn-ui/apps/v4/registry/bases/base");
});

test("resolves official New York v4 imports without rewriting them", () => {
  const alias = config.resolve.alias.find(
    ({ find }) => find === "@/registry/new-york-v4",
  );

  assert.ok(alias);
  assert.equal(
    alias.replacement,
    resolve(here, "../src/upstream/shadcn_new_york_v4"),
  );
});
