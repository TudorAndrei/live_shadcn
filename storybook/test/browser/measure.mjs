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

  const walk = (element, path) => {
    for (const child of element.children) {
      const slot = child.getAttribute("data-slot");
      const here = slot ? [...path, slot] : path;

      if (slot) {
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
    }
  };

  walk(root, []);

  const box = root.getBoundingClientRect();

  return {
    // The component as a whole, so a difference that moves everything is
    // reported once rather than on every part inside it.
    whole: { width: round(box.width), height: round(box.height) },
    slots: found,
  };
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
