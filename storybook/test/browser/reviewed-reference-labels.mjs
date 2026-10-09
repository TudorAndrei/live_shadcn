const RULE = "collapsible-settings-radius-labels";

export function reviewedReferenceLabels(component, example) {
  return component === "collapsible" && example === "settings"
    ? {
        id: RULE,
        reason: "The pinned settings inputs share id=radius. Their authored Radius X/Y labels target radius-x/y. Compare those intended names while preserving the port's correct label links.",
      }
    : null;
}

export async function referenceLabelNames(scope, policy) {
  if (!policy) return [];
  if (policy.id !== RULE) throw new Error("Unknown reference label rule");

  return scope.evaluate((root) => {
    const fail = () => { throw new Error("The reviewed Collapsible settings label pattern changed"); };
    if (root.id !== "preview-collapsible-settings") fail();
    const trigger = root.querySelector("[aria-expanded]");
    const inputs = [...root.querySelectorAll("input")];
    const count = trigger?.getAttribute("aria-expanded") === "true" ? 4 : 2;
    if (inputs.length !== count || root.querySelectorAll("label").length !== count) fail();

    return inputs.map((input, index) => {
      const axis = index % 2 === 0 ? "x" : "y";
      const labels = input.closest("[data-slot='field']")?.querySelectorAll("label");
      const label = labels?.[0];
      const name = label?.innerText.replace(/\s+/g, " ").trim();
      if (
        input.id !== "radius" || input.type !== "text" || input.labels.length !== 0 ||
        input.hasAttribute("aria-label") || input.hasAttribute("aria-labelledby") ||
        labels?.length !== 1 || label.htmlFor !== `radius-${axis}` ||
        name !== `Radius ${axis.toUpperCase()}`
      ) fail();
      return name;
    });
  });
}
