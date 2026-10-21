// The official example catalog is stored as source names in document order.
// Build the local ids with the same rules as the Elixir verifier. A repeated id
// uses the full source name, so `button-demo` and `button-default` cannot both
// claim `default`.
//
// A documentation page can embed an example owned by a related component.
// Keep that source with its rendering component, as the Elixir verifier does.
const sourceOwners = new Map([[
  "card-rtl",
  "card",
]]);

export function entries(component, sources) {
  const used = new Set();

  return sources
    .map(entry)
    .filter(({ source }) => owns(component, source))
    .map(({ id: explicitId, reference, source }) => {
      const candidate =
        explicitId ??
        (component === "chart" && source === "chart-demo"
          ? "demo"
          : source === `${component}-demo`
          ? "default"
          : source.startsWith(`${component}-`)
            ? source.slice(component.length + 1)
            : source);

      const options = [candidate, source];
      let suffix = 2;
      let id;

      while (!id) {
        const option = options.shift() ?? `${source}-${suffix++}`;
        if (!used.has(option)) id = option;
      }

      used.add(id);
      return reference ? { id, source, reference } : { id, source };
    });
}

function entry(source) {
  return typeof source === "string" ? { source } : source;
}

function owns(component, source) {
  return !sourceOwners.has(source) || sourceOwners.get(source) === component;
}
