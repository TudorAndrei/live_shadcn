// Shared background accessibility for open modal layers. Scroll locking and
// keyboard focus stay with the component that owns those behaviors.
//
// Each colocated hook is bundled on its own, so Overlay, Drawer and Floating
// each carry a copy of this module. The stack lives on `globalThis` so that
// every copy reads the same one.
const accessibilityDocuments =
  (globalThis[Symbol.for("live_base.modal_accessibility")] ??= new WeakMap());

export function accessibilityInside(popup) {
  const document = popup.ownerDocument;
  const inside = new Set([popup]);
  const candidates = [...document.querySelectorAll(
    "[data-lb-anchor][data-open], [data-lb-trigger][data-open], [data-phx-teleported-src]",
  )];
  let changed;
  do {
    changed = false;
    for (const node of candidates) {
      if (inside.has(node)) continue;
      const anchor = document.getElementById(
        node.getAttribute("data-lb-anchor") || node.getAttribute("data-lb-trigger"),
      );
      const source = document.getElementById(node.getAttribute("data-phx-teleported-src"));
      const attached = [...inside].some((target) =>
        (anchor && target.contains(anchor)) ||
        (source && target.contains(source) && node.querySelector("[data-open]")),
      );
      if (attached) {
        inside.add(node);
        changed = true;
      }
    }
  } while (changed);
  return inside;
}

function outsideNodes(document, allowed) {
  const ancestors = new Set();
  for (const target of allowed) {
    for (let node = target; node; node = node.parentElement) ancestors.add(node);
  }
  const outside = new Set();
  const collect = (parent) => {
    for (const node of parent.children) {
      if (node.matches("script, template") || allowed.has(node)) continue;
      // A display: contents portal transports controls without adding its own
      // accessible box. Mark its outside children, not the transport wrapper.
      if (ancestors.has(node) || document.defaultView.getComputedStyle(node).display === "contents") {
        collect(node);
      } else {
        outside.add(node);
      }
    }
  };
  collect(document.body);
  return outside;
}

function refreshAccessibility(state, records = []) {
  const pending = [...records, ...state.observer.takeRecords()];
  for (const record of pending) {
    if (record.attributeName === "aria-hidden" && state.hidden.has(record.target)) {
      state.hidden.set(record.target, record.target.getAttribute("aria-hidden"));
    }
  }
  // Disconnect for our own writes. Pending caller changes above become the
  // values restored later, and our mask writes cannot start an observer loop.
  state.observer.disconnect();
  const front = state.owners.findLast((owner) =>
    owner.element.isConnected && owner.element.hasAttribute("data-open"));
  const inside = front ? front.inside() : new Set();
  const allowed = new Set([...inside, ...state.document.querySelectorAll("[aria-live]")]);
  const outside = front ? outsideNodes(state.document, allowed) : new Set();
  for (const [node, value] of state.hidden) {
    if (outside.has(node)) continue;
    if (value === null) node.removeAttribute("aria-hidden");
    else node.setAttribute("aria-hidden", value);
    state.hidden.delete(node);
  }
  for (const node of outside) {
    if (!state.hidden.has(node)) state.hidden.set(node, node.getAttribute("aria-hidden"));
    if (node.getAttribute("aria-hidden") !== "true") node.setAttribute("aria-hidden", "true");
  }
  if (state.owners.length) {
    state.observer.observe(state.document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["aria-hidden", "aria-live", "data-open", "hidden", "class", "style"],
    });
  }
}

export function holdAccessibility(element, inside = () => accessibilityInside(element)) {
  const document = element.ownerDocument;
  let state = accessibilityDocuments.get(document);
  if (!state) {
    state = { document, owners: [], hidden: new Map() };
    state.observer = new document.defaultView.MutationObserver((records) => refreshAccessibility(state, records));
    accessibilityDocuments.set(document, state);
  }
  const lease = { element, inside, state, released: false };
  state.owners.push(lease);
  refreshAccessibility(state);
  return lease;
}

export function releaseAccessibility(lease) {
  if (!lease || lease.released) return;
  lease.released = true;
  const state = lease.state;
  state.owners = state.owners.filter((owner) => owner !== lease);
  refreshAccessibility(state);
  if (state.owners.length) return;
  state.observer.disconnect();
  accessibilityDocuments.delete(state.document);
}
