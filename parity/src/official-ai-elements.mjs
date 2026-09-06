import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");

// The pinned manifest stores every public AI Elements example. A source file
// must import exactly one component that its filename can name. This excludes
// application demos and fails on a new ambiguous prefix relationship.
export function entries(manifest, sourceReader = readPinnedSource) {
  return discovery(manifest, sourceReader).entries;
}

export function problems(manifest, sourceReader = readPinnedSource) {
  return discovery(manifest, sourceReader).problems;
}

export function discovery(manifest, sourceReader = readPinnedSource) {
  const files = Object.keys(manifest.files || {});
  const components = files
    .filter((path) => path.startsWith("ai_elements/") && path.endsWith(".tsx"))
    .map((path) => path.slice("ai_elements/".length, -".tsx".length))
    .sort();

  const result = { entries: [], problems: [] };

  for (const source of files
    .filter((path) => path.startsWith("ai_examples/") && path.endsWith(".tsx"))
    .map((path) => path.slice("ai_examples/".length, -".tsx".length))
    .sort()) {
    const candidates = components.filter(
      (name) => source === name || source.startsWith(name + "-"),
    );
    const imports = [...sourceReader(source).matchAll(/@repo\/elements\/([a-z0-9-]+)/g)]
      .map((match) => match[1])
      .filter((name, index, all) => all.indexOf(name) === index);
    const owned = candidates.filter((name) => imports.includes(name));

    if (owned.length === 0 && candidates.length === 0) continue;

    if (owned.length === 0) {
      result.problems.push(
        `${source}: filename candidates ${candidates.join(", ")} are not imported`,
      );
      continue;
    }

    if (owned.length > 1) {
      result.problems.push(
        `${source}: imports more than one filename candidate: ${owned.join(", ")}`,
      );
      continue;
    }

    const [component] = owned;
    result.entries.push({
      component,
      id: source === component ? "default" : source.slice(component.length + 1),
      source,
    });
  }

  return result;
}

function readPinnedSource(source) {
  return readFileSync(join(root, "registry/upstream/ai_examples", `${source}.tsx`), "utf8");
}
