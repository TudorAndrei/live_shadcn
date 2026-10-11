import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const policies = JSON.parse(
  readFileSync(join(here, "../../../registry/VERIFICATION_POLICY.json"), "utf8"),
);

export function componentName(source, component) {
  const prefix = `${source}-`;
  return component.startsWith(prefix) ? component.slice(prefix.length) : component;
}

export function policy(source, component, example) {
  const name = componentName(source, component);

  if (source === "ai_elements") {
    return policies._ai_elements;
  }

  return policies[`${source}/${name}`] ?? { kind: "standard" };
}

export function comparisonApplies(source, component, example) {
  return source === "shadcn" && policy(source, component, example).kind === "standard";
}
