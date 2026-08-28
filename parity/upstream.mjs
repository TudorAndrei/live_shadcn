import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { cp, mkdir, readFile, rm } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const run = promisify(execFile);
const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "..");
const manifest = JSON.parse(
  await readFile(join(repo, "registry/UPSTREAM.json"), "utf8"),
);
const checkoutRoot = resolve(
  process.env.UPSTREAM_CHECKOUT_ROOT || join(here, ".upstream"),
);
const to = join(here, "src/upstream");

async function git(args) {
  return run("git", args, { maxBuffer: 10 * 1024 * 1024 });
}

async function checkout(name, source) {
  const target = join(checkoutRoot, name);

  if (!existsSync(join(target, ".git"))) {
    await mkdir(checkoutRoot, { recursive: true });
    await git([
      "clone",
      "--filter=blob:none",
      "--no-checkout",
      "https://github.com/" + source.repo + ".git",
      target,
    ]);
  }

  try {
    await git(["-C", target, "cat-file", "-e", source.ref + "^{commit}"]);
  } catch {
    await git(["-C", target, "fetch", "--depth", "1", "origin", source.ref]);
  }

  await git(["-C", target, "checkout", "--detach", "--force", source.ref]);
  const { stdout } = await git(["-C", target, "rev-parse", "HEAD"]);

  if (stdout.trim() !== source.ref) {
    throw new Error(name + " checkout is not at " + source.ref);
  }

  return target;
}

const ai = await checkout("ai-elements", manifest.sources.ai_elements);
const shadcn = await checkout("shadcn-ui", manifest.sources.shadcn);

const directories = {
  // Keep the base/ui layout that the official examples import.
  shadcn: dirname(join(shadcn, manifest.sources.shadcn.dir)),
  ai_elements: join(ai, manifest.sources.ai_elements.dir),
  ai_examples: join(ai, manifest.sources.ai_elements.examples_dir),
  ai_shadcn: join(ai, manifest.sources.ai_elements.shadcn_dir),
};

await rm(to, { force: true, recursive: true });
await mkdir(to, { recursive: true });

for (const [directory, from] of Object.entries(directories)) {
  await cp(from, join(to, directory), {
    recursive: true,
    filter: (sourcePath) =>
      !sourcePath.includes(directory + "/styles") &&
      !sourcePath.includes(directory + "/theme") &&
      !(directory === "ai_shadcn" && sourcePath.endsWith("/tsconfig.json")),
  });
}

console.log("copied pinned official checkouts to " + to);
