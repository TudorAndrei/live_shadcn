import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const policies = JSON.parse(
  readFileSync(join(here, "../../../registry/VERIFICATION_POLICY.json"), "utf8"),
);
const aiAudit = JSON.parse(readFileSync(join(here, "ai-component-audit.json"), "utf8"));

export function componentName(source, component) {
  const prefix = `${source}-`;
  return component.startsWith(prefix) ? component.slice(prefix.length) : component;
}

export function policy(source, component, example) {
  const name = componentName(source, component);

  if (source === "ai_elements" && aiAudit[name]?.local_only_examples?.includes(example)) {
    return { kind: "local_only", reason: "approved local fixture" };
  }

  return policies[`${source}/${name}`] ?? { kind: "standard" };
}

export function comparisonApplies(source, component, example) {
  return policy(source, component, example).kind === "standard";
}
