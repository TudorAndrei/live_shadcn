// Drawer behavior that cannot be expressed with Phoenix.LiveView.JS alone.
//
// The hook extends the shared overlay contract with four drawer facts:
// pointer swipes, snap-point offsets, nested stack state, and a viewport that
// stays mounted until the closing transition has finished.

import { Overlay } from "./overlay.js";
import { duration } from "./transition.js";

const OPEN = "data-open";
const SWIPING = "data-swiping";
const MOVEMENT_X = "--drawer-swipe-movement-x";
const MOVEMENT_Y = "--drawer-swipe-movement-y";
const PROGRESS = "--drawer-swipe-progress";
const STRENGTH = "--drawer-swipe-strength";
const SNAP_OFFSET = "--drawer-snap-point-offset";

export const Drawer = {
  ...Overlay,

  mounted() {
    this.viewport = document.getElementById(this.el.getAttribute("data-lb-viewport"));
    this.trigger = document.getElementById(this.el.getAttribute("data-lb-trigger"));
    this.snapPoints = readSnapPoints(this.el.getAttribute("data-lb-snap-points"));
    this.activeSnapIndex = 0;

    this.onPointerDown = (event) => this.pointerDown(event);
    this.onPointerMove = (event) => this.pointerMove(event);
    this.onPointerUp = (event) => this.pointerUp(event);
    this.onOutsidePointerDown = (event) => this.outsidePointerDown(event);
    this.onDrawerKeydown = (event) => this.drawerKeydown(event);

    this.el.addEventListener("pointerdown", this.onPointerDown);
    document.addEventListener("pointerdown", this.onOutsidePointerDown, true);
    document.addEventListener("keydown", this.onDrawerKeydown, true);

    this.resizeObserver = new ResizeObserver(() => this.measure());
    this.resizeObserver.observe(this.el);

    Overlay.mounted.call(this);
    this.resetSwipe();
    updateStacks();
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onPointerDown);
    document.removeEventListener("pointerdown", this.onOutsidePointerDown, true);
    document.removeEventListener("keydown", this.onDrawerKeydown, true);
    this.removePointerListeners();
    this.resizeObserver?.disconnect();
    clearTimeout(this.viewportTimer);
    Overlay.destroyed.call(this);
    updateStacks();
  },

  enter(animate) {
    clearTimeout(this.viewportTimer);
    this.popupHeight = 0;
    this.el.style.removeProperty("--drawer-height");
    if (this.viewport) this.viewport.hidden = false;
    Overlay.enter.call(this, animate);
    requestAnimationFrame(() => {
      this.measure();
      this.applySnapPoint(this.activeSnapIndex);
      updateStacks();
    });
  },

  leave() {
    this.cancelSwipe();
    Overlay.leave.call(this);
    clearTimeout(this.viewportTimer);
    this.viewportTimer = setTimeout(() => {
      if (!this.open && this.viewport) this.viewport.hidden = true;
      updateStacks();
    }, duration(this.el));
    updateStacks();
  },

  measure() {
    if (!this.open || this.el.hidden) return;
    // A stacked popup is visually scaled. Keep its own layout height rather
    // than feeding that scale back into the size on every resize callback.
    const nested = [...document.querySelectorAll("[data-slot='drawer-popup'][data-lb-parent]")]
      .some((drawer) => hasDrawerAncestor(drawer, this.el));
    const height = this.popupHeight > 0 && nested ? this.popupHeight : this.el.offsetHeight;
    this.popupHeight = height;
    this.el.style.setProperty("--drawer-height", `${height}px`);
    this.resolvedSnapPoints = resolveSnapPoints(this.snapPoints, height);
    if (this.resolvedSnapPoints.length > 0) this.applySnapPoint(this.activeSnapIndex);
    updateStacks();
  },

  applySnapPoint(index) {
    if (!this.resolvedSnapPoints || this.resolvedSnapPoints.length === 0) {
      this.el.style.setProperty(SNAP_OFFSET, "0px");
      return;
    }

    this.activeSnapIndex = Math.max(0, Math.min(index, this.resolvedSnapPoints.length - 1));
    const direction = this.el.getAttribute("data-swipe-direction");
    const offset = this.resolvedSnapPoints[this.activeSnapIndex].offset;
    const progress = this.resolvedSnapPoints.length === 1
      ? 0
      : 1 - this.activeSnapIndex / (this.resolvedSnapPoints.length - 1);
    this.el.style.setProperty(SNAP_OFFSET, `${direction === "up" ? -offset : offset}px`);
    this.setLayerVariable(PROGRESS, String(progress));
  },

  pointerDown(event) {
    if (!this.open || event.button > 0 || this.drag) return;

    const handle = event.target.closest("[data-slot='drawer-swipe-handle']");
    if (!handle && event.pointerType === "mouse") return;
    if (!handle && event.target.closest("button, input, select, textarea, a[href]")) return;

    this.drag = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      at: performance.now(),
      movement: 0,
    };

    this.el.setPointerCapture?.(event.pointerId);
    window.addEventListener("pointermove", this.onPointerMove, { passive: false });
    window.addEventListener("pointerup", this.onPointerUp);
    window.addEventListener("pointercancel", this.onPointerUp);
  },

  pointerMove(event) {
    if (!this.drag || event.pointerId !== this.drag.id) return;
    const direction = this.el.getAttribute("data-swipe-direction") || "down";
    const raw = direction === "down" || direction === "up"
      ? event.clientY - this.drag.y
      : event.clientX - this.drag.x;
    const movement = this.resolvedSnapPoints?.length > 1 && (direction === "down" || direction === "up")
      ? raw
      : closingMovement(direction, raw);

    if (Math.abs(movement) < 2) return;
    event.preventDefault();
    this.drag.movement = movement;
    this.markSwiping(true);

    const axisVariable = direction === "down" || direction === "up" ? MOVEMENT_Y : MOVEMENT_X;
    this.el.style.setProperty(axisVariable, `${movement}px`);
    this.setLayerVariable(axisVariable, `${movement}px`);

    const size = direction === "down" || direction === "up"
      ? this.el.getBoundingClientRect().height
      : this.el.getBoundingClientRect().width;
    const progress = Math.min(1, Math.abs(movement) / Math.max(1, size));
    this.setLayerVariable(PROGRESS, String(progress));
    markAncestorSwiping(this.el, true);
  },

  pointerUp(event) {
    if (!this.drag || event.pointerId !== this.drag.id) return;

    const elapsed = Math.max(1, performance.now() - this.drag.at);
    const movement = this.drag.movement;
    const velocity = Math.abs(movement) / elapsed;
    const direction = this.el.getAttribute("data-swipe-direction") || "down";
    const size = direction === "down" || direction === "up"
      ? this.el.getBoundingClientRect().height
      : this.el.getBoundingClientRect().width;

    this.setLayerVariable(STRENGTH, String(Math.max(0.1, Math.min(1, velocity))));
    this.removePointerListeners();
    this.drag = null;
    this.markSwiping(false);
    markAncestorSwiping(this.el, false);

    if (this.resolvedSnapPoints?.length > 1 && (direction === "down" || direction === "up")) {
      const closingSign = direction === "down" ? 1 : -1;
      const signedMovement = movement * closingSign;
      const moved = Math.abs(movement) > 40 || velocity > 0.5;
      const next = moved
        ? signedMovement > 0
          ? this.activeSnapIndex - 1
          : this.activeSnapIndex + 1
        : this.activeSnapIndex;

      if (moved && next < 0) {
        this.closeDrawer();
        return;
      }

      this.resetSwipe();
      this.applySnapPoint(next);
      return;
    }

    if (Math.abs(movement) > size * 0.25 || velocity > 0.5) {
      this.closeDrawer();
    } else {
      this.resetSwipe();
    }
  },

  cancelSwipe() {
    this.removePointerListeners();
    this.drag = null;
    this.markSwiping(false);
    markAncestorSwiping(this.el, false);
    this.resetSwipe();
  },

  removePointerListeners() {
    window.removeEventListener("pointermove", this.onPointerMove);
    window.removeEventListener("pointerup", this.onPointerUp);
    window.removeEventListener("pointercancel", this.onPointerUp);
  },

  markSwiping(active) {
    for (const layer of this.layers()) {
      active ? layer.setAttribute(SWIPING, "") : layer.removeAttribute(SWIPING);
    }
  },

  setLayerVariable(name, value) {
    for (const layer of this.layers()) layer.style.setProperty(name, value);
  },

  resetSwipe() {
    for (const layer of this.layers()) {
      layer.style.setProperty(MOVEMENT_X, "0px");
      layer.style.setProperty(MOVEMENT_Y, "0px");
      layer.style.setProperty(PROGRESS, "0");
      layer.style.setProperty(STRENGTH, "1");
    }
  },

  drawerKeydown(event) {
    if (
      event.key !== "Escape" ||
      !this.open ||
      event.defaultPrevented ||
      !this.el.hasAttribute("data-lb-dismissible")
    ) return;
    if (frontmostOpenDrawer() !== this.el) return;
    event.preventDefault();
    this.closeDrawer();
  },

  outsidePointerDown(event) {
    if (
      !this.open ||
      !this.el.hasAttribute("data-lb-dismissible") ||
      this.el.hasAttribute("data-lb-disable-pointer-dismissal")
    ) return;
    if (this.el.contains(event.target) || this.trigger?.contains(event.target)) return;
    if (frontmostOpenDrawer() !== this.el) return;
    this.closeDrawer();
  },

  closeDrawer() {
    if (!this.open) return;
    this.trigger?.removeAttribute("data-popup-open");
    this.trigger?.setAttribute("aria-expanded", "false");

    for (const layer of this.layers()) {
      layer.removeAttribute(OPEN);
      layer.setAttribute("data-closed", "");
    }

    requestAnimationFrame(() => this.trigger?.focus({ preventScroll: true }));
  },
};

function readSnapPoints(value) {
  if (!value) return [];
  try {
    const points = JSON.parse(value);
    return Array.isArray(points) ? points : [];
  } catch (_error) {
    return [];
  }
}

function resolveSnapPoints(points, popupHeight) {
  const viewportHeight = window.innerHeight;
  const rootFontSize = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;

  return points
    .map((point) => {
      let height = null;

      if (typeof point === "number") {
        height = point <= 1 ? point * viewportHeight : point;
      } else if (typeof point === "string" && point.endsWith("rem")) {
        height = parseFloat(point) * rootFontSize;
      } else if (typeof point === "string" && point.endsWith("px")) {
        height = parseFloat(point);
      }

      if (!Number.isFinite(height)) return null;
      const clamped = Math.max(0, Math.min(height, popupHeight, viewportHeight));
      return { height: clamped, offset: Math.max(0, popupHeight - clamped) };
    })
    .filter(Boolean);
}

function closingMovement(direction, movement) {
  if (direction === "down" || direction === "right") return Math.max(0, movement);
  return Math.min(0, movement);
}

function openDrawers() {
  return [...document.querySelectorAll("[data-slot='drawer-popup'][data-open]")];
}

function frontmostOpenDrawer() {
  const drawers = openDrawers();
  return drawers.find((drawer) => !drawers.some((other) => other !== drawer && hasDrawerAncestor(other, drawer))) || null;
}

function updateStacks() {
  const drawers = [...document.querySelectorAll("[data-slot='drawer-popup']")];
  const state = new Map(drawers.map((drawer) => [drawer, { count: 0, frontmost: null }]));

  for (const drawer of drawers.filter((item) => item.hasAttribute(OPEN))) {
    let ancestor = parentDrawer(drawer);

    while (ancestor) {
      const entry = state.get(ancestor);
      if (entry) {
        entry.count += 1;
        entry.frontmost = drawer;
      }
      ancestor = parentDrawer(ancestor);
    }
  }

  for (const drawer of drawers) {
    const entry = state.get(drawer);
    drawer.style.setProperty("--nested-drawers", String(entry.count));

    if (entry.count > 0) {
      drawer.setAttribute("data-nested-drawer-open", "");
      drawer.style.setProperty(
        "--drawer-frontmost-height",
        entry.frontmost.style.getPropertyValue("--drawer-height") || `${entry.frontmost.offsetHeight}px`,
      );
    } else {
      drawer.removeAttribute("data-nested-drawer-open");
      drawer.removeAttribute("data-nested-drawer-swiping");
      const height = drawer.style.getPropertyValue("--drawer-height");
      if (height) drawer.style.setProperty("--drawer-frontmost-height", height);
      else drawer.style.removeProperty("--drawer-frontmost-height");
    }
  }
}

function markAncestorSwiping(drawer, active) {
  let ancestor = parentDrawer(drawer);

  while (ancestor) {
    active
      ? ancestor.setAttribute("data-nested-drawer-swiping", "")
      : ancestor.removeAttribute("data-nested-drawer-swiping");
    ancestor = parentDrawer(ancestor);
  }
}

function parentDrawer(drawer) {
  const parent = drawer.getAttribute("data-lb-parent");
  return parent ? document.getElementById(parent) : null;
}

function hasDrawerAncestor(drawer, ancestor) {
  let parent = parentDrawer(drawer);
  while (parent) {
    if (parent === ancestor) return true;
    parent = parentDrawer(parent);
  }
  return false;
}
