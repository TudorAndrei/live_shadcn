import { animate } from "motion";

const running = new WeakMap();
const ACTIVE_ENTRY_ATTRIBUTE = "data-lb-message-entry-active";

export const MESSAGE_ANIMATION_PRESETS = Object.freeze({
  fade: {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    transition: { duration: 0.22, ease: "easeOut" },
  },
  "slide-up": {
    initial: { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.26, ease: [0.16, 1, 0.3, 1] },
  },
  "slide-side": {
    initial: { opacity: 0, x: 18 },
    animate: { opacity: 1, x: 0 },
    transition: { duration: 0.28, ease: [0.16, 1, 0.3, 1] },
  },
  pop: {
    initial: { opacity: 0, scale: 0.94, y: 6, originX: 1, originY: 1 },
    animate: { opacity: 1, y: 0, scale: 1 },
    transition: { type: "spring", stiffness: 500, damping: 34, mass: 0.7 },
  },
  "spring-bounce": {
    initial: { opacity: 0, y: 12, scale: 0.96 },
    animate: { opacity: 1, y: 0, scale: 1 },
    transition: { type: "spring", stiffness: 520, damping: 30, mass: 0.7 },
  },
  "blur-fade": {
    initial: { opacity: 0, filter: "blur(4px)", y: 6 },
    animate: { opacity: 1, y: 0, filter: "blur(0px)" },
    transition: { duration: 0.28, ease: "easeOut" },
  },
  "scale-fade": {
    initial: { opacity: 0, scale: 0.98 },
    animate: { opacity: 1, scale: 1 },
    transition: { duration: 0.24, ease: "easeOut" },
  },
});

function transform({ x = 0, y = 0, scale = 1 }) {
  const parts = [];

  if (x) parts.push(`translateX(${x}px)`);
  if (y) parts.push(`translateY(${y}px)`);
  if (scale !== 1) parts.push(`scale(${scale})`);

  return parts.length === 0 ? "none" : parts.join(" ");
}

function writeState(element, state) {
  if (state.opacity !== undefined) element.style.opacity = String(state.opacity);
  if (state.filter !== undefined) element.style.filter = state.filter;

  if (state.x !== undefined || state.y !== undefined || state.scale !== undefined) {
    element.style.transform = transform(state);
  }

  if (state.originX !== undefined || state.originY !== undefined) {
    const x = (state.originX ?? 0.5) * 100;
    const y = (state.originY ?? 0.5) * 100;
    element.style.transformOrigin = `${x}% ${y}% 0px`;
  }
}

function keyframes(preset) {
  const frames = {};

  for (const property of ["opacity", "x", "y", "scale", "filter"]) {
    if (preset.animate[property] === undefined) continue;
    frames[property] = [
      preset.initial[property] ?? preset.animate[property],
      preset.animate[property],
    ];
  }

  return frames;
}

function reducedMotion() {
  return globalThis.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
}

export function animateMessageEntry(element, presetId) {
  const preset = MESSAGE_ANIMATION_PRESETS[presetId];

  running.get(element)?.stop();
  running.delete(element);
  element.removeAttribute(ACTIVE_ENTRY_ATTRIBUTE);

  if (!preset) return null;

  if (reducedMotion()) {
    writeState(element, preset.animate);
    return null;
  }

  writeState(element, preset.initial);
  element.setAttribute(ACTIVE_ENTRY_ATTRIBUTE, "true");
  let controls;

  try {
    controls = animate(element, keyframes(preset), preset.transition);
  } catch (error) {
    element.removeAttribute(ACTIVE_ENTRY_ATTRIBUTE);
    throw error;
  }

  running.set(element, controls);

  const complete = () => {
    if (running.get(element) !== controls) return;
    writeState(element, preset.animate);
    running.delete(element);
    element.removeAttribute(ACTIVE_ENTRY_ATTRIBUTE);
  };

  controls.finished.then(complete, complete);
  return controls;
}

export function stopMessageEntry(element) {
  running.get(element)?.stop();
  running.delete(element);
  element.removeAttribute(ACTIVE_ENTRY_ATTRIBUTE);
}
