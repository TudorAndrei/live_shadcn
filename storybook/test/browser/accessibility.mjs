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

export async function stableViolations(page, violations, selector) {
  return Promise.all(
    violations.map(async (violation) => ({
      ...violation,
      nodes: await Promise.all(
        violation.nodes.map(async (node) => ({
          ...node,
          stableTarget: await stableTarget(page, node.target, selector),
        })),
      ),
    })),
  );
}

async function stableTarget(page, target, selector) {
  if (
    !Array.isArray(target) ||
    target.length !== 1 ||
    typeof target[0] !== "string"
  )
    return null;

  try {
    return await page.locator(target[0]).first().evaluate((element, selector) => {
      const segments = [];
      // Popup parts can be outside the preview DOM tree. Use a physical owner
      // first. An external popup can use the selected preview only when the
      // page has exactly one preview. Keep its slot and visible occurrence.
      // Portal transport wrappers do not identify a component part.
      const popupSlots = new Set([
        "dialog-content",
        "alert-dialog-content",
        "drawer-popup",
        "popover-content",
        "hover-card-content",
        "sheet-content",
        "context-menu-content",
        "context-menu-sub-content",
        "dropdown-menu-content",
        "dropdown-menu-sub-content",
        "menubar-content",
        "navigation-menu-content",
        "tooltip-content",
      ]);
      const popup = element.closest(
        [...popupSlots].map((slot) => `[data-slot="${slot}"]`).join(","),
      );
      const preview = document.querySelector(selector);
      const solePreview = document.querySelectorAll("[data-preview]").length === 1
        ? preview
        : null;
      const ownerOf = (node) => node.closest("[data-preview]") || solePreview;

      for (let current = element; current; current = current.parentElement) {
        const preview = current.getAttribute("data-preview");
        const slot = current.getAttribute("data-slot");

        if (preview) {
          segments.unshift(`preview:${preview}`);
          break;
        }

        if (slot) {
          const peers = current === popup
            ? [...document.querySelectorAll(`[data-slot="${slot}"]`)].filter(
              (candidate) => ownerOf(candidate) === ownerOf(current) &&
                candidate.getClientRects().length > 0,
            )
            : current.parentElement
              ? [...current.parentElement.children].filter(
                (candidate) => candidate.getAttribute("data-slot") === slot && candidate.getClientRects().length > 0,
              )
              : [current];
          const occurrence = peers.length > 1
            ? `:${peers.indexOf(current) + 1}`
            : "";
          segments.unshift(`slot:${slot}${occurrence}`);
          if (current === popup) {
            const owner = ownerOf(current)?.getAttribute("data-preview");
            if (owner) segments.unshift(`preview:${owner}`);
            break;
          }
        }
      }

      if (!element.hasAttribute("data-slot") && !element.hasAttribute("data-preview")) {
        const text = element.textContent.replace(/\s+/g, " ").trim().slice(0, 80);
        const role = element.getAttribute("role");
        const peers = element.parentElement
          ? [...element.parentElement.children].filter(
              (candidate) =>
                candidate.tagName === element.tagName && candidate.getAttribute("role") === role,
            )
          : [element];
        const occurrence =
          peers.length > 1 ? `:${peers.indexOf(element) + 1}` : "";
        segments.push(
          `node:${element.tagName.toLowerCase()}:${role || ""}:${text}${occurrence}`,
        );
      }

      return segments.length > 0 ? segments.join(" > ") : null;
    }, selector);
  } catch {
    return null;
  }
}
