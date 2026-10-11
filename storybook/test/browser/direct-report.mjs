import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { source as componentSource } from "./registries.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const aiAudit = JSON.parse(readFileSync(resolve(root, "storybook/test/browser/ai-component-audit.json"), "utf8"));

export function exportIdentity({ source, name, layer, previewKey, examples }) {
  const output = execFileSync("mix", ["verification.identity", `${source}/${name}`,
    "--layer", layer, "--preview-key", previewKey, "--examples", examples.join(",")],
  { cwd: resolve(root, "tools"), encoding: "utf8" });
  const json = output.trim().split("\n").findLast((line) => line.startsWith("{"));
  if (!json) throw new Error("Mix did not export a verification identity");
  return JSON.parse(json);
}

export function directEnvelope(arguments_, environment, identity = exportIdentity,
  index = JSON.parse(readFileSync(resolve(root, "registry/snapshot/index.json"), "utf8"))) {
  const selected = environment.PREVIEW_COMPONENT
    ? [environment.PREVIEW_COMPONENT]
    : (environment.PREVIEW_COMPONENTS || "").split(",").filter(Boolean);
  const project = arguments_[arguments_.indexOf("--project") + 1];
  const files = arguments_.filter((argument) => argument.endsWith(".spec.mjs"));
  const aiBehavior = selected.length === 1 && files.length === 1 &&
    aiAudit[selected[0]]?.spec === files[0];
  const layer = aiBehavior ? "behavior"
    : files.length === 1 && files[0] === "accessibility.spec.mjs" ? "accessibility"
    : files.length === 1 && files[0] === "parity.spec.mjs" ? "parity"
    : project === "pixel" && (files.length === 0 || files.length === 1 && files[0] === "pixel.spec.mjs") ? "pixel"
    : null;
  const diagnostic = arguments_.some((argument) =>
    /^(?:--(?:grep|grep-invert|shard|repeat-each|last-failed|only-changed|list|test-list|test-list-invert|max-failures)|-g|-x)(?:=|$)/.test(argument));
  if (selected.length !== 1 || !layer || diagnostic) {
    return { version: 2, source: environment.PREVIEW_SOURCE || "shadcn", name: "diagnostic", layer: "diagnostic",
      preview_key: "diagnostic", examples: [], states: {}, completed: false };
  }
  const previewKey = selected[0];
  const source = componentSource(previewKey);
  const current = index[previewKey];
  if (!Array.isArray(current)) throw new Error(`unknown preview component ${previewKey}`);
  if (!source || (environment.PREVIEW_SOURCE && environment.PREVIEW_SOURCE !== source)) {
    throw new Error(`preview component ${previewKey} does not match the selected source`);
  }
  const examples = (environment.PREVIEW_EXAMPLE || environment.PREVIEW_EXAMPLES || "")
    .split(",").filter(Boolean);
  const scope = examples.length ? [...new Set(examples)].sort() : [...current].sort();
  if (scope.some((example) => !current.includes(example))) throw new Error("unknown preview example");
  if (layer === "behavior" && JSON.stringify(scope) !== JSON.stringify([...current].sort())) {
    return { version: 2, source, name: "diagnostic", layer: "diagnostic",
      preview_key: "diagnostic", examples: [], states: {}, completed: false };
  }
  return identity({ source, name: previewKey.replace(/^(?:shadcn|ai_elements)-/, ""),
    layer, previewKey, examples: scope });
}
