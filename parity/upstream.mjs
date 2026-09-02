import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { cp, mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

import {
  cleanGeneratedSources,
  publishRelease,
  releasePath,
  sourceLeasePath,
  stagingPath,
  useSourceLease,
} from "./source-lease.mjs";
import { entries } from "./src/official-shadcn.mjs";

const run = promisify(execFile);
const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
const manifest = JSON.parse(
  await readFile(join(repo, "registry/UPSTREAM.json"), "utf8"),
);
const previews = JSON.parse(
  await readFile(join(repo, "registry/snapshot/index.json"), "utf8"),
);
const checkoutRoot = resolve(
  process.env.UPSTREAM_CHECKOUT_ROOT || join(here, ".upstream"),
);
const sourceDirectory = join(here, "src");
const to = join(sourceDirectory, "upstream");

async function git(args, signal) {
  return run("git", args, { maxBuffer: 10 * 1024 * 1024, signal });
}

async function checkout(name, source, { assertLease, signal }) {
  const target = join(checkoutRoot, name);

  await assertLease();

  if (!existsSync(join(target, ".git"))) {
    await assertLease();
    await mkdir(checkoutRoot, { recursive: true });
    await git([
      "clone",
      "--filter=blob:none",
      "--no-checkout",
      "https://github.com/" + source.repo + ".git",
      target,
    ], signal);
    await assertLease();
  }

  try {
    await git(["-C", target, "cat-file", "-e", source.ref + "^{commit}"], signal);
  } catch (error) {
    if (signal?.aborted) throw error;
    await assertLease();
    await git(["-C", target, "fetch", "--depth", "1", "origin", source.ref], signal);
  }

  await assertLease();
  await git(["-C", target, "checkout", "--detach", "--force", source.ref], signal);
  await assertLease();
  const { stdout } = await git(["-C", target, "rev-parse", "HEAD"], signal);

  if (stdout.trim() !== source.ref) {
    throw new Error(name + " checkout is not at " + source.ref);
  }

  return target;
}

await useSourceLease(sourceLeasePath(here), process.env.PARITY_SOURCE_LEASE_TOKEN, async (lease) => {
  const { assertLease } = lease;
  await assertLease();
  await cleanGeneratedSources(sourceDirectory, to);

  const staging = stagingPath(sourceDirectory);
  const release = releasePath(sourceDirectory);
  let published = false;

  try {
    const ai = await checkout("ai-elements", manifest.sources.ai_elements, lease);
    const shadcn = await checkout("shadcn-ui", manifest.sources.shadcn, lease);

    const directories = {
  // Keep the base/ui layout that the official examples import.
  shadcn: dirname(join(shadcn, manifest.sources.shadcn.dir)),
  // The component documentation renders these examples. Keep them separate
  // from the registry examples above because they are the public reference
  // for the states that the Storybook copies.
  shadcn_examples: join(shadcn, "apps/v4/examples/base"),
  shadcn_app_components: join(shadcn, "apps/v4/components"),
  shadcn_app_hooks: join(shadcn, "apps/v4/hooks"),
  shadcn_app_lib: join(shadcn, "apps/v4/lib"),
  shadcn_icons: join(shadcn, "apps/v4/registry/icons"),
  shadcn_helpers: join(shadcn, "packages/helpers/src"),
  ai_elements: join(ai, manifest.sources.ai_elements.dir),
  ai_examples: join(ai, manifest.sources.ai_elements.examples_dir),
  ai_shadcn: join(ai, manifest.sources.ai_elements.shadcn_dir),
    };

    await assertLease();
    await rm(staging, { force: true, recursive: true });
    await assertLease();
    await mkdir(staging, { recursive: true });

    for (const [directory, from] of Object.entries(directories)) {
      await assertLease();
      await cp(from, join(staging, directory), {
        recursive: true,
        filter: (sourcePath) =>
          !sourcePath.includes(directory + "/styles") &&
          !sourcePath.includes(directory + "/theme") &&
          !(directory === "ai_shadcn" && sourcePath.endsWith("/tsconfig.json")),
      });
      await assertLease();
    }

    await assertLease();
    await writeFile(
      join(staging, "shadcn_examples/catalog.json"),
      JSON.stringify(manifest.examples.shadcn),
    );

    const imports = [];
    const exports = [];
    const officialComponents = new Set(
      Object.keys(manifest.files)
        .filter((path) => path.startsWith("shadcn/ui/") && path.endsWith(".tsx"))
        .map((path) => path.slice("shadcn/ui/".length, -".tsx".length))
        .map((name) => previews[name] ? name : previews[`shadcn-${name}`] ? `shadcn-${name}` : null)
        .filter(Boolean),
    );
    let index = 0;

    for (const [component, sources] of Object.entries(manifest.examples.shadcn)) {
  const storybook = previews[component]
    ? component
    : previews[`shadcn-${component}`]
      ? `shadcn-${component}`
      : null;
  if (!storybook) continue;

  const local = new Set(previews[storybook]);

  for (const { id, source } of entries(component, sources)) {
    if (!local.has(id)) continue;

    const body = await readFile(join(staging, `shadcn_examples/${source}.tsx`), "utf8");
    const named = body.match(/export\s+function\s+([A-Za-z_$][A-Za-z0-9_$]*)/);
    const symbol = `OfficialExample${index++}`;

    if (/export\s+default\s+function/.test(body)) {
      imports.push(`import ${symbol} from "./${source}";`);
    } else if (named) {
      imports.push(`import { ${named[1]} as ${symbol} } from "./${source}";`);
    } else {
      throw new Error(`${source}.tsx has no exported example function`);
    }

    exports.push(`  ${JSON.stringify(`${storybook}.${id}`)}: ${symbol},`);
  }
    }

    await assertLease();
    await writeFile(
      join(staging, "shadcn_examples/official.tsx"),
      `${imports.join("\n")}\n\nexport const officialComponents = new Set(${JSON.stringify([...officialComponents].sort())});\n\nexport default {\n${exports.join("\n")}\n};\n`,
    );

    await assertLease();
    await rename(staging, release);
    await assertLease();
    await publishRelease(release, to);
    published = true;

    console.log("copied pinned official checkouts to " + to);
  } finally {
    await rm(staging, { force: true, recursive: true });
    if (!published) await rm(release, { force: true, recursive: true });
  }
});
