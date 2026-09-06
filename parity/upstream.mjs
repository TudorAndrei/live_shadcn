import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { cp, mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
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
import { pinnedSourceDirectories } from "./upstream-directories.mjs";

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
const officialExamplesPath = join(here, "official-examples.json");

async function git(args, signal) {
  return run("git", args, { maxBuffer: 10 * 1024 * 1024, signal });
}

async function writeJsonAtomically(path, value) {
  const temporary = join(
    dirname(path),
    `.${basename(path)}.${randomUUID()}.tmp`,
  );

  try {
    await writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`);
    await rename(temporary, path);
  } finally {
    await rm(temporary, { force: true });
  }
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

    const directories = pinnedSourceDirectories({ ai, shadcn, manifest });

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
    const officialExamples = {};
    const sonnerToastExamples = [];
    // A docs page can publish a complete composite example without a matching
    // registry primitive. Data Table, Date Picker, and Typography are such
    // pages. Their keys are manifest evidence too, and must select the pinned
    // React source in `main.tsx` just like a registry component does.
    const sourceComponents = Object.keys(manifest.files)
      .filter((path) => path.startsWith("shadcn/ui/") && path.endsWith(".tsx"))
      .map((path) => path.slice("shadcn/ui/".length, -".tsx".length));
    const officialComponents = new Set(
      [...sourceComponents, ...Object.keys(manifest.examples.shadcn)]
        .map((name) => previews[name] ? name : previews[`shadcn-${name}`] ? `shadcn-${name}` : null)
        .filter(Boolean),
    );
    let index = 0;

    for (const [component, sources] of Object.entries(manifest.examples.shadcn)) {
      const componentEntries = entries(component, sources);

      if (componentEntries.length === 0) continue;

      const storybook = previews[component]
        ? component
        : previews[`shadcn-${component}`]
          ? `shadcn-${component}`
          : null;

      if (!storybook) {
        throw new Error(`${component} has no Storybook page`);
      }

      const local = new Set(previews[storybook]);

      for (const { id, source, reference } of componentEntries) {
        if (!local.has(id)) {
          throw new Error(`${storybook}.${id} has no Storybook example`);
        }

        const symbol = `OfficialExample${index++}`;
        const key = `${storybook}.${id}`;
        const sourcePath = source.split("#", 1)[0];
        const body = await readFile(
          join(staging, sourcePath.startsWith("shadcn/") ? sourcePath : `shadcn_examples/${source}.tsx`),
          "utf8",
        );

        if (reference) {
          const [module, exported] = reference.split("#");

          if (!module || !exported) {
            throw new Error(`${source} has an invalid supplemental reference`);
          }

          imports.push(`import { ${exported} as ${symbol} } from "../../reference/${module}";`);
          officialExamples[key] = source;
        } else {
          const named = body.match(/export\s+function\s+([A-Za-z_$][A-Za-z0-9_$]*)/);

          if (/export\s+default\s+function/.test(body)) {
            imports.push(`import ${symbol} from "./${source}";`);
            officialExamples[key] = `shadcn_examples/${source}.tsx#default`;
          } else if (named) {
            imports.push(`import { ${named[1]} as ${symbol} } from "./${source}";`);
            officialExamples[key] = `shadcn_examples/${source}.tsx#${named[1]}`;
          } else {
            throw new Error(`${source}.tsx has no exported example function`);
          }
        }

        if (/\btoast\s*\(/.test(body) && /from\s+["']sonner["']/.test(body)) {
          sonnerToastExamples.push(key);
        }

        exports.push(`  ${JSON.stringify(key)}: ${symbol},`);
      }
    }

    await assertLease();
    await writeFile(
      join(staging, "shadcn_examples/official.tsx"),
      `${imports.join("\n")}\n\nexport const officialComponents = new Set(${JSON.stringify([...officialComponents].sort())});\nexport const sonnerToastExamples = new Set(${JSON.stringify(sonnerToastExamples.sort())});\n\nexport default {\n${exports.join("\n")}\n};\n`,
    );

    await assertLease();
    await rename(staging, release);
    await assertLease();
    await publishRelease(release, to);
    published = true;

    await assertLease();
    await writeJsonAtomically(officialExamplesPath, officialExamples);
    await assertLease();

    console.log("copied pinned official checkouts to " + to);
  } finally {
    await rm(staging, { force: true, recursive: true });
    if (!published) await rm(release, { force: true, recursive: true });
  }
});
