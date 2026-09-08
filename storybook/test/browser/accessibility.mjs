const PAGE_CHROME = new Set(["page-has-heading-one"]);

// Axe gives every affected node a selector target. A port may inherit an
// upstream violation only at that same target. Counting nodes by rule lets a
// local violation replace an upstream one and hides the regression.
export function regressions(port, upstream) {
  const inherited = new Set(
    upstream.flatMap(({ id, nodes }) => nodes.map((node) => violationNodeKey(id, node))),
  );

  return port
    .filter(({ id }) => !PAGE_CHROME.has(id))
    .flatMap(({ id, help, nodes }) =>
      nodes
        .filter((node) => !inherited.has(violationNodeKey(id, node)))
        .map(
          (node) =>
            `${id}: ${help} (port target ${target(node)} has no matching upstream violation): ${first(node)}`,
        ),
    )
    .sort();
}

function violationNodeKey(id, node) {
  return `${id}\u0000${target(node)}`;
}

function target(node) {
  return JSON.stringify(
    node.stableTarget ? [node.stableTarget] : node.target || [],
  );
}

function first(node) {
  const check = [...(node.any || []), ...(node.all || []), ...(node.none || [])][0];
  const message = check?.message || node.failureSummary || "";
  const data = check?.data ? ` ${JSON.stringify(check.data)}` : "";
  const nodeTarget = node.target?.length ? ` at ${node.target.join(" ")}` : "";

  return `${message}${data}${nodeTarget}`;
}
