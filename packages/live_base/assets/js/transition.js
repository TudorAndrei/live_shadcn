// Showing and hiding something that animates.
//
// Three hooks need the same four steps, so they share them rather than each
// getting them slightly wrong:
//
//   1. remove `hidden` before measuring or animating — a hidden box has no size
//   2. flush the starting state so the browser has something to animate from
//   3. on the way out, mark the ending state and wait
//   4. add `hidden` only once the animation has finished, or an element
//      disappears mid-transition
//
// `data-starting-style` and `data-ending-style` are Base UI's names, and shadcn
// class strings key on them. Nothing here invents a name.

const STARTING = "data-starting-style";
const ENDING = "data-ending-style";

/**
 * Shows every layer and, unless `animate` is false, flushes the starting state
 * so the transition has somewhere to come from.
 */
export function show(layers, animate = true) {
  for (const layer of layers) {
    layer.removeAttribute(ENDING);
    layer.hidden = false;
  }

  if (!animate) return;

  mark(layers, STARTING);
  layers[0].offsetHeight;
  unmark(layers, STARTING);
}

/**
 * Marks the ending state, waits as long as the class strings say the animation
 * takes, and then hides. Returns the timer so a caller that is shown again
 * mid-exit can cancel it.
 */
export function hide(layers) {
  mark(layers, ENDING);

  return setTimeout(() => {
    unmark(layers, ENDING);
    for (const layer of layers) layer.hidden = true;
  }, duration(layers[0]));
}

export function mark(layers, attribute) {
  for (const layer of layers) layer.setAttribute(attribute, "");
}

export function unmark(layers, attribute) {
  for (const layer of layers) layer.removeAttribute(attribute);
}

/**
 * How long the class strings say it takes, in milliseconds.
 *
 * Reading the computed style beats listening for `transitionend`, which never
 * fires when there is nothing to transition — and a component whose style sheet
 * animates nothing is the common case.
 */
export function duration(element) {
  const style = getComputedStyle(element);
  const times = [style.transitionDuration, style.transitionDelay, style.animationDuration];
  return Math.max(...times.map(seconds)) * 1000;
}

// "0.15s, 0s" -> 0.15
function seconds(list) {
  return Math.max(0, ...String(list).split(",").map((value) => parseFloat(value) || 0));
}
