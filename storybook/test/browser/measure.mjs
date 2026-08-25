// What a page says about itself, in the terms both renderers share.
//
// The comparison is not of markup. Two renderers of the same component differ
// in ways nobody should be told about — React generates `base-ui-_r_2_` where
// the generated component takes an id from its caller, and only one side has
// `phx-click`. What they must agree on is what a reader sees: where each part
// of the component is, how big it is, and what it looks like.
//
// `data-slot` is the vocabulary. shadcn writes one on every part, the spec is
// built around them, and both renderers emit the same ones — so a slot is a
// name both sides can be asked about.

// Enough to catch "this looks different", and no more. Every property here is
// one a class string sets and a reader would notice; a longer list would report
// inherited values that differ because a parent differs, twice.
export const PROPERTIES = [
  "display",
  "position",
  "box-sizing",
  "padding-top",
  "padding-right",
  "padding-bottom",
  "padding-left",
  "margin-top",
  "margin-right",
  "margin-bottom",
  "margin-left",
  "border-top-width",
  "border-right-width",
  "border-bottom-width",
  "border-left-width",
  "border-top-left-radius",
  "border-top-right-radius",
  "border-bottom-right-radius",
  "border-bottom-left-radius",
  "border-top-color",
  "background-color",
  "color",
  "font-family",
  "font-size",
  "font-weight",
  "line-height",
  "letter-spacing",
  "text-align",
  "gap",
  "flex-direction",
  "flex-wrap",
  "align-items",
  "justify-content",
  "opacity",
  "visibility",
  "overflow-x",
  "overflow-y",
];

// Runs in the page. Everything it needs is passed in as one argument, because a
// browser context shares nothing with the file that wrote the function and
// `page.evaluate` hands over exactly one.
export function collect({ selector, properties }) {
  const root = document.querySelector(selector);
  if (!root) return null;

  const origin = root.getBoundingClientRect();
  const seen = new Map();
  const found = [];

  const round = (n) => Math.round(n * 10) / 10;

  const record = (child, path) => {
    // Hidden nodes have no visual or accessibility presence. LiveView keeps
    // them ready for a client-side state change; Base UI can unmount them.
    // Compare the state a reader can see, not that implementation detail.
    if (child.hidden) return;

    const slot = child.getAttribute("data-slot");
    const here = slot ? [...path, slot] : path;
    const portal = slot?.endsWith("-portal");

    // A portal is a transport wrapper, not a visible component part. React
    // mounts it beside the preview root, while LiveView keeps it in the root,
    // so its host box is different by design. Its children still use the
    // portal in their path and are compared normally.
    if (slot && !portal) {
      // A component draws three badges and each is `badge`. The path says
      // where in the anatomy an element sits; the count says which of the
      // ones sitting there it is.
      const name = here.join(" > ");
      const at = seen.get(name) ?? 0;
      seen.set(name, at + 1);

      const box = child.getBoundingClientRect();
      const style = getComputedStyle(child);

      found.push({
        slot: at === 0 ? name : `${name} #${at + 1}`,
        box: {
          x: round(box.x - origin.x),
          y: round(box.y - origin.y),
          width: round(box.width),
          height: round(box.height),
        },
        style: Object.fromEntries(properties.map((p) => [p, style.getPropertyValue(p)])),
      });
    }

    walk(child, here);
  };

  const walk = (element, path) => {
    for (const child of element.children) {
      record(child, path);
    }
  };

  walk(root, []);

  // React portals live beside the preview root. Their slots still belong to
  // this example and need the same origin as the inline LiveView equivalent.
  for (const portal of document.querySelectorAll("[data-slot]")) {
    if (!root.contains(portal) && !portal.parentElement?.closest("[data-slot]")) {
      record(portal, []);
    }
  }

  const box = root.getBoundingClientRect();

  return {
    // The component as a whole, so a difference that moves everything is
    // reported once rather than on every part inside it.
    whole: { width: round(box.width), height: round(box.height) },
    slots: found,
  };
}

// Every element, not only the ones wearing a `data-slot`.
//
// `collect` compares the vocabulary the two renderers share, and that
// vocabulary can be very small: a calendar carries exactly one `data-slot`,
// because `<DayPicker>` draws a whole month grid behind it. So a real
// difference — seven weekday headings reading `Sun` where React reads `Su` —
// arrives as `width — React 157.2, Phoenix 165.7` and names nothing.
//
// This is not a second check. It runs only when a comparison has already
// failed, and it exists to answer the next question a person asks: *where*.
export function outline({ selector, limit }) {
  const root = document.querySelector(selector);
  if (!root) return [];

  const rows = [];
  const round = (n) => Math.round(n * 100) / 100;

  const walk = (element, depth) => {
    if (rows.length >= limit) return;

    const box = element.getBoundingClientRect();

    // What a reader cannot see is not part of what the two renderers draw.
    // `collect` skips `hidden` for the same reason; this adds the other way a
    // page hides something, which is the preview page's own `sr-only` headings
    // — chrome that belongs to the fixture rather than to the component, and
    // that would otherwise head every report of every failing example.
    if (element.hidden || screenReaderOnly(element, box)) return;

    rows.push({
      depth,
      tag: element.tagName.toLowerCase(),
      slot: element.getAttribute("data-slot") || "",
      width: round(box.width),
      height: round(box.height),
      // Leaf text only. An ancestor's `textContent` is every descendant's, and
      // repeating it on the way down buries the row that actually holds it.
      text: element.children.length === 0 ? element.textContent.trim().slice(0, 40) : "",
      class: element.getAttribute("class") || "",
    });

    for (const child of element.children) walk(child, depth + 1);
  };

  // Clipped to nothing, in a box no bigger than a pixel. That is what every
  // `sr-only` utility comes down to, whichever of the two spellings it uses.
  function screenReaderOnly(element, box) {
    if (box.width > 1 || box.height > 1) return false;

    const style = getComputedStyle(element);

    return (
      style.position === "absolute" &&
      (style.clipPath === "inset(50%)" || style.clip === "rect(0px, 0px, 0px, 0px)")
    );
  }

  walk(root, 0);
  return rows;
}

/** One outline row as a line of text. */
export function describeRow(row) {
  if (!row) return "<nothing>";

  return [
    "  ".repeat(row.depth) + row.tag,
    `${row.width}x${row.height}`,
    row.slot && `[${row.slot}]`,
    row.text && JSON.stringify(row.text),
    row.class,
  ]
    .filter(Boolean)
    .join(" ");
}

// Half a pixel. Text rendering puts a box at 61.328125 on one side and 61.33 on
// the other, and a report that said so would bury the difference that matters.
const TOLERANCE = 0.5;

export function compare(react, phoenix) {
  if (!react || !phoenix) {
    return [{ slot: "(the page)", kind: "missing", react: !!react, phoenix: !!phoenix }];
  }

  const differences = [];

  for (const [what, reactValue] of Object.entries(react.whole)) {
    const phoenixValue = phoenix.whole[what];
    if (Math.abs(reactValue - phoenixValue) > TOLERANCE) {
      differences.push({ slot: "(the whole)", property: what, react: reactValue, phoenix: phoenixValue });
    }
  }

  const byName = (list) => new Map(list.map((entry) => [entry.slot, entry]));
  const left = byName(react.slots);
  const right = byName(phoenix.slots);

  for (const slot of left.keys()) {
    if (!right.has(slot)) differences.push({ slot, kind: "only in React" });
  }

  for (const slot of right.keys()) {
    if (!left.has(slot)) differences.push({ slot, kind: "only in Phoenix" });
  }

  for (const [slot, a] of left) {
    const b = right.get(slot);
    if (!b) continue;

    for (const [what, value] of Object.entries(a.box)) {
      if (Math.abs(value - b.box[what]) > TOLERANCE) {
        differences.push({ slot, property: what, react: value, phoenix: b.box[what] });
      }
    }

    for (const [what, value] of Object.entries(a.style)) {
      if (value !== b.style[what]) {
        differences.push({ slot, property: what, react: value, phoenix: b.style[what] });
      }
    }
  }

  return differences;
}
