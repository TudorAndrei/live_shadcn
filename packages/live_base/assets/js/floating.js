// The floating-position hook.
//
// Where a popup lands is a measurement: it depends on where its anchor is, how
// much room is left below it, and how wide the viewport happens to be at that
// moment. None of that is expressible as a Phoenix.LiveView.JS command, which
// is why the architecture reserved a hook for it from the start.
//
// What the hook writes is not styling of its own. Base UI documents every one
// of these, and shadcn's class strings read them:
//
//   data-side           top | right | bottom | left — where it actually landed
//   data-align          start | center | end
//   data-anchor-hidden  present when the anchor has scrolled out of sight
//   --anchor-width      the anchor's width, for a popup that matches it
//   --anchor-height
//   --available-width   how much room was left, for a popup that has to fit
//   --available-height
//   --transform-origin  the corner it should appear to grow from
//
// Declared on the positioner:
//
//   data-lb-anchor     the id of the element it is positioned against
//   data-lb-side       the side asked for, before the room available says otherwise
//   data-lb-semantic-side  an optional logical side name exposed to component CSS
//   data-lb-align      the alignment asked for
//   data-lb-offset     the gap between anchor and popup, in pixels
//   data-lb-align-offset  the cross-axis adjustment, in pixels
//   data-lb-popup      on the element inside it that is styled and animated
//   data-lb-fractional keeps the exact coordinate in left and top for components
//                      whose upstream positioner does not use a rounded transform
//   data-lb-autofocus  present when opening should move the focus into the
//                      popup — true of a popover and a menu, false of a tooltip,
//                      which would otherwise take the focus off what a reader
//                      was already reading

import {
  arrow,
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
  size,
} from "@floating-ui/dom";

import { hide, show } from "./transition.js";
import { accessibilityInside, holdAccessibility, releaseAccessibility } from "./modal_accessibility.js";

const ORIGIN = { top: "bottom", bottom: "top", left: "right", right: "left" };
const ITEM_ALIGN_MARGIN = 10;
const ITEM_ALIGN_PADDING = 5;
const ITEM_ALIGN_TRIGGER_COLLISION_THRESHOLD = 20;
const SCROLL_EDGE_TOLERANCE = 1;
const FOCUSABLE = [
  "a[href]",
  "button:not(:disabled)",
  "input:not(:disabled)",
  "select:not(:disabled)",
  "textarea:not(:disabled)",
  "[tabindex]:not([tabindex='-1'])",
].join(",");

export const Floating = {
  mounted() {
    this.anchor = document.getElementById(this.el.getAttribute("data-lb-anchor"));
    this.openedByKeyboard = false;
    this.markPointerOpen = () => (this.openedByKeyboard = false);
    this.markKeyboardOpen = (event) => {
      if (["Enter", " ", "ArrowDown", "ArrowUp"].includes(event.key)) this.openedByKeyboard = true;
    };
    this.anchor?.addEventListener("pointerdown", this.markPointerOpen);
    this.anchor?.addEventListener("keydown", this.markKeyboardOpen);
    this.arrow = this.el.querySelector("[data-lb-arrow]");
    this.dismissOwner = this.findDismissOwner();
    this.dismissOutside = (event) => this.onDismissOutside(event);
    this.open = this.el.hasAttribute("data-open");
    this.popup = this.el.querySelector("[data-lb-popup]") || this.el;
    this.syncScroll = () => this.syncScrollArrows();
    this.popup.addEventListener("scroll", this.syncScroll);
    this.syncPlacementRequest();
    this.reposition = () => this.place();
    this.el.addEventListener("live-base:reposition", this.reposition);

    if (this.open) {
      show(this.layers(), false);
      this.attach();
    }

    this.observer = new MutationObserver((records) => this.attributesChanged(records));
    this.observer.observe(this.el, {
      attributes: true,
      attributeFilter: ["data-open", "data-lb-side", "data-lb-semantic-side", "data-lb-align"],
    });
  },

  destroyed() {
    this.detach();
    clearTimeout(this.timer);
    this.observer?.disconnect();
    this.popup?.removeEventListener("scroll", this.syncScroll);
    this.anchor?.removeEventListener("pointerdown", this.markPointerOpen);
    this.anchor?.removeEventListener("keydown", this.markKeyboardOpen);
    this.el.removeEventListener("live-base:reposition", this.reposition);
  },

  // The positioner is moved and the popup is animated, so both are shown and
  // hidden together.
  layers() {
    return this.popup === this.el ? [this.el] : [this.el, this.popup];
  },

  stateChanged() {
    const open = this.el.hasAttribute("data-open");
    if (open === this.open) return;
    this.open = open;

    if (open) {
      clearTimeout(this.timer);
      this.itemAlignmentDisabled = false;
      show(this.layers());
      this.attach();
      this.takeFocus();
    } else {
      this.detach();
      this.returnFocus();
      this.timer = hide(this.layers());
    }
  },

  attributesChanged(records) {
    if (records.some((record) => record.attributeName !== "data-open")) {
      this.syncPlacementRequest();
      if (this.open) this.place();
    }

    this.stateChanged();
  },

  syncPlacementRequest() {
    this.requestedSide = this.el.getAttribute("data-lb-side") || "bottom";
    this.requestedSemanticSide =
      this.el.getAttribute("data-lb-semantic-side") || this.requestedSide;
    this.requestedAlign = this.el.getAttribute("data-lb-align") || "center";
  },

  // The focus moves once the popup is on the page, which is why it is the
  // hook's to do: a `JS` command runs before `hidden` has been removed, and a
  // hidden element cannot be focused.
  takeFocus() {
    if (!this.el.hasAttribute("data-lb-autofocus")) return;
    this.returnTo = document.activeElement;
    const selectedOption = this.popup.hasAttribute("data-lb-initial-highlight")
      ? this.popup.querySelector("[role='option'][data-selected]:not([data-disabled])") ||
        this.popup.querySelector("[role='option']:not([data-disabled])")
      : null;
    const highlighted = selectedOption;

    if (highlighted) {
      highlighted.setAttribute("data-highlighted", "");
    }
    const firstMenuItem = this.popup.matches("[data-lb-roving='menuitem']")
      ? this.popup.querySelector("[role^='menuitem']:not([data-disabled])")
      : null;
    const activeMenuItem = this.openedByKeyboard ? firstMenuItem : null;

    if (activeMenuItem) activeMenuItem.setAttribute("data-highlighted", "");
    const target =
      highlighted ||
      activeMenuItem ||
      this.popup.querySelector("[autofocus]") ||
      this.popup.querySelector(FOCUSABLE) ||
      this.popup;
    target.focus({ preventScroll: true });
  },

  returnFocus() {
    if (this.el.hasAttribute("data-lb-return-focus-to-trigger")) {
      // A LiveView patch can replace the selected calendar day before this
      // close action runs. Return to the declared trigger even if the active
      // element is then the document body.
      this.anchor?.focus({ preventScroll: true });
    } else if (
      !this.el.hasAttribute("data-lb-no-return-focus") &&
      this.returnTo &&
      this.popup.contains(document.activeElement)
    ) {
      this.returnTo.focus({ preventScroll: true });
    }

    this.returnTo = null;
  },

  // While it is open the position is kept current: the page can scroll, the
  // window can resize, and the anchor can move under it.
  attach() {
    if (!this.anchor || this.cleanup) return;
    this.cleanup = autoUpdate(this.reference(), this.el, () => this.place());
    if (this.el.getAttribute("data-lb-accessibility") === "modal") {
      this.accessibilityLease = holdAccessibility(this.el, () => this.accessibilityInside());
    }
    if (this.dismissOwner) document.addEventListener("click", this.dismissOutside);
  },

  detach() {
    releaseAccessibility(this.accessibilityLease);
    this.accessibilityLease = null;
    document.removeEventListener("click", this.dismissOutside);
    this.cleanup?.();
    this.cleanup = null;
  },

  // Some owners have no visible rectangle. Menus also own portaled child
  // popups through their parent-trigger chain. Run their declared close command
  // from this layer, and retain the native click-away owners for other popups.
  findDismissOwner() {
    const ownerId = this.el.getAttribute("data-lb-dismiss-owner");
    const owner = ownerId
      ? document.getElementById(ownerId)
      : this.el.closest("[data-lb-dismiss-command], [phx-click-away]");
    if (!owner) return null;
    if (owner === this.el) return owner;
    if (this.el.getAttribute("data-lb-anchor") !== `${owner.id}-trigger`) return null;
    return owner;
  },

  onDismissOutside(event) {
    if (!this.el.hasAttribute("data-open")) return;
    if (this.anchor?.contains(event.target) || this.owns(event.target)) return;

    const command =
      this.dismissOwner?.getAttribute("data-lb-dismiss-command") ||
      this.dismissOwner?.getAttribute("phx-click-away");
    if (command) this.liveSocket.execJS(this.dismissOwner, command, "click");
  },

  // A submenu is portaled outside its parent popup. Follow its parent-trigger
  // chain before treating a click as an outside click. This keeps every menu
  // in the open branch visible until the user clicks outside the full branch.
  owns(target) {
    if (this.el.contains(target)) return true;

    let popup = target.closest?.("[data-lb-popup]");

    while (popup?.hasAttribute("data-lb-submenu")) {
      const trigger = document.getElementById(popup.getAttribute("data-lb-parent-trigger"));
      if (!trigger) return false;
      if (this.el.contains(trigger)) return true;
      popup = trigger.closest("[data-lb-popup]");
    }

    return false;
  },

  accessibilityInside() {
    const inside = accessibilityInside(this.el);
    // A menu branch can move to separate body portals. Preserve every logical
    // child that the existing dismiss owner treats as part of this branch.
    for (const popup of this.el.ownerDocument.querySelectorAll("[data-lb-popup]")) {
      if (this.owns(popup)) inside.add(popup);
    }
    return inside;
  },

  async place() {
    const pointReference = this.hasPointReference();
    const middleware = [
      offset(this.offsetOptions()),
      flip({ padding: this.flipPadding(), mainAxis: !pointReference }),
      shift({ padding: 5, crossAxis: pointReference }),
      size({
        padding: 5,
        apply: ({ availableWidth, availableHeight, rects }) => {
          const viewport = this.el.ownerDocument.documentElement;
          const width = pointReference ? viewport.clientWidth - 10 : availableWidth;
          const height = pointReference ? viewport.clientHeight - 10 : availableHeight;
          const anchor = snapAnchorDimensions(
            rects.reference,
            this.el.ownerDocument.defaultView?.devicePixelRatio || 1,
          );
          this.el.style.setProperty("--anchor-width", `${anchor.width}px`);
          this.el.style.setProperty("--anchor-height", `${anchor.height}px`);
          this.el.style.setProperty("--available-width", `${width}px`);
          this.el.style.setProperty("--available-height", `${height}px`);
        },
      }),
    ];

    if (this.arrow) middleware.push(arrow({ element: this.arrow, padding: 4 }));

    let { x, y, placement, middlewareData } = await computePosition(this.reference(), this.el, {
      placement: this.placement(),
      strategy: "fixed",
      middleware,
    });

    const [side, align = "center"] = placement.split("-");

    // SelectPopup first waits for Floating UI to position the outer element,
    // then reads that exact rectangle before it replaces the coordinates. Do
    // not round this step: the measured left edge is an input to the final
    // item-aligned left value.
    this.placeInitialItemAlignmentPosition(x, y);
    const aligned = this.itemAlignedPosition(x, y);

    const positioned = aligned.itemAligned
      ? aligned
      : this.el.hasAttribute("data-lb-fractional")
        ? aligned
        : { x: roundByDPR(this.el, aligned.x), y: roundByDPR(this.el, aligned.y) };

    if (aligned.itemAligned) {
      // SelectPopup has already written its final left/top/bottom styles.
    } else if (this.el.hasAttribute("data-lb-fractional")) {
      Object.assign(this.el.style, {
        position: "fixed",
        left: `${positioned.x}px`,
        top: `${positioned.y}px`,
        bottom: "",
        marginTop: "",
        marginBottom: "",
        transform: "none",
      });
    } else {
      Object.assign(this.el.style, {
        position: "fixed",
        left: "0px",
        top: "0px",
        bottom: "",
        marginTop: "",
        marginBottom: "",
        transform: `translate(${positioned.x}px, ${positioned.y}px)`,
      });
    }

    this.syncScrollArrows();

    const semanticSide = this.semanticSide(side);
    this.el.setAttribute("data-side", semanticSide);
    this.el.setAttribute("data-align", align);
    this.popup.setAttribute("data-side", semanticSide);
    this.popup.setAttribute("data-align", align);
    this.el.style.setProperty("--transform-origin", ORIGIN[side]);

    this.el.toggleAttribute("data-anchor-hidden", !!middlewareData.hide?.referenceHidden);
    this.placeArrow(middlewareData.arrow, semanticSide, align);
  },

  placeArrow(position, side, align) {
    if (!this.arrow || !position) return;

    const { x, y } = position;
    Object.assign(this.arrow.style, {
      position: "absolute",
      left: x == null ? "" : `${x}px`,
      top: y == null ? "" : `${y}px`,
      right: "",
      bottom: "",
    });

    this.arrow.setAttribute("data-side", side);
    this.arrow.setAttribute("data-align", align);
  },

  // Floating UI uses physical sides for its calculations. Base UI keeps a
  // requested logical side on the rendered popup and arrow. If collision
  // handling flips the popup, expose the opposite logical side.
  semanticSide(actualSide) {
    if (!["inline-start", "inline-end"].includes(this.requestedSemanticSide)) {
      return actualSide;
    }

    if (actualSide === this.requestedSide) return this.requestedSemanticSide;
    return this.requestedSemanticSide === "inline-start" ? "inline-end" : "inline-start";
  },

  itemAlignedPosition(x, y) {
    if (!this.el.hasAttribute("data-lb-align-item") || this.itemAlignmentDisabled) return { x, y };

    const item =
      this.popup.querySelector("[role='option'][data-selected]") ||
      this.popup.querySelector("[role='option']:not([data-disabled])");
    if (!item) return { x, y };

    // This is the SelectPopup measurement phase. Popup transforms are removed
    // only while the source reads rectangles, then restored before painting.
    const restoreTransformStyles = unsetTransformStyles(this.popup);

    try {
      const value = this.anchor.querySelector("[data-slot='select-value']");
      const text = item.querySelector(".cn-select-item-text");
      const win = this.el.ownerDocument.defaultView;
      const positionerStyles = win.getComputedStyle(this.el);
      const popupStyles = win.getComputedStyle(this.popup);
      const scale = floatingScale(this.anchor);
      const triggerRect = normalizeRect(this.anchor.getBoundingClientRect(), scale);
      const positionerRect = normalizeRect(this.el.getBoundingClientRect(), scale);
      const valueRect = value ? normalizeRect(value.getBoundingClientRect(), scale) : null;
      const textRect = text ? normalizeRect(text.getBoundingClientRect(), scale) : null;
      const marginTop = parseFloat(positionerStyles.marginTop) || ITEM_ALIGN_MARGIN;
      const marginBottom = parseFloat(positionerStyles.marginBottom) || ITEM_ALIGN_MARGIN;
      const minHeight = parseFloat(positionerStyles.minHeight) || 100;
      const maxPopupHeight = getMaxPopupHeight(popupStyles);
      const viewport = this.el.ownerDocument.documentElement;
      const layout = selectItemAlignmentLayout({
        direction: selectItemAlignmentDirection(this.el, this.popup),
        triggerRect,
        positionerRect,
        valueRect,
        textRect,
        viewportWidth: viewport.clientWidth,
        viewportHeight: viewport.clientHeight,
        scrollHeight: this.popup.scrollHeight,
        borderBottom: parseFloat(popupStyles.borderBottomWidth),
        marginTop,
        marginBottom,
        minHeight,
      });

      Object.assign(this.el.style, {
        left: `${layout.left}px`,
        height: `${layout.height}px`,
        maxHeight: "none",
        marginTop: `${marginTop}px`,
        marginBottom: `${marginBottom}px`,
        transform: "none",
      });
      this.popup.style.height = "100%";

      const final = selectItemAlignmentFinal(layout, {
        maxScrollTop: getMaxScrollTop(this.popup),
        positionerHeight: positionerRect.height,
        maxPopupHeight,
      });

      if (final.fallback) {
        this.itemAlignmentDisabled = true;
        this.clearItemAlignmentStyles();
        return { x, y };
      }

      this.el.style.height = `${final.height}px`;
      this.el.style.top = final.top;
      this.el.style.bottom = final.bottom;
      this.popup.scrollTop = final.scrollTop;

      if (textRect) {
        const textCenterY = textRect.top + textRect.height / 2;
        const originY = clamp(
          positionerRect.height > 0
            ? ((textCenterY - positionerRect.top) / positionerRect.height) * 100
            : 50,
          0,
          100,
        );
        this.popup.style.setProperty("--transform-origin", `50% ${originY}%`);
      }

      return { x: layout.left, y: final.height, itemAligned: true };
    } finally {
      restoreTransformStyles();
    }
  },

  placeInitialItemAlignmentPosition(x, y) {
    if (!this.el.hasAttribute("data-lb-align-item") || this.itemAlignmentDisabled) return;

    Object.assign(this.el.style, {
      position: "fixed",
      left: "0px",
      top: "0px",
      right: "",
      bottom: "",
      transform: `translate(${x}px, ${y}px)`,
    });
  },

  clearItemAlignmentStyles() {
    Object.assign(this.el.style, {
      height: "",
      maxHeight: "",
      marginTop: "",
      marginBottom: "",
      bottom: "",
    });
    this.popup.style.height = "";
  },

  syncScrollArrows() {
    const up = this.popup.querySelector("[data-slot='select-scroll-up-button']");
    const down = this.popup.querySelector("[data-slot='select-scroll-down-button']");
    if (!up || !down) return;

    up.hidden = this.popup.scrollTop <= 0.5;
    down.hidden = this.popup.scrollTop + this.popup.clientHeight >= this.popup.scrollHeight - 0.5;
  },

  // What was asked for. Where it ends up is what `flip` decides, and that is
  // what `data-side` reports.
  placement() {
    const side = this.requestedSide;
    const align = this.requestedAlign;
    return align === "center" ? side : `${side}-${align}`;
  },

  // Base UI passes the raw alignOffset. Floating UI applies the direction
  // of the positioner when it converts this value to browser coordinates.
  crossAxisOffset() {
    return Number(this.el.getAttribute("data-lb-align-offset")) || 0;
  },

  // Base UI passes alignOffset as both crossAxis and alignmentAxis. Floating
  // UI reverses alignmentAxis for an `end` placement. Without it, an input
  // popover with align="end" and alignOffset={-8} is 16px too far left.
  offsetOptions() {
    const alignAxis = this.crossAxisOffset();
    return {
      mainAxis: Number(this.el.getAttribute("data-lb-offset")) || 0,
      crossAxis: alignAxis,
      alignmentAxis: alignAxis,
    };
  },

  // Base UI uses five pixels of collision padding and adds a one-pixel bias
  // toward the requested side. This prevents an exact edge fit from changing
  // the requested side after a later layout update.
  flipPadding() {
    const padding = { top: 6, right: 6, bottom: 6, left: 6 };
    padding[ORIGIN[this.requestedSide]] += 1;
    return padding;
  },

  reference() {
    const pointX = this.el.getAttribute("data-lb-point-x");
    const pointY = this.el.getAttribute("data-lb-point-y");
    if (pointX == null || pointY == null) return this.anchor;

    const x = Number(pointX);
    const y = Number(pointY);
    if (!Number.isFinite(x) || !Number.isFinite(y)) return this.anchor;

    return {
      getBoundingClientRect: () => ({
        x,
        y,
        top: y,
        right: x,
        bottom: y,
        left: x,
        width: 0,
        height: 0,
      }),
    };
  },

  hasPointReference() {
    const pointX = this.el.getAttribute("data-lb-point-x");
    const pointY = this.el.getAttribute("data-lb-point-y");
    if (pointX == null || pointY == null) return false;

    const x = Number(pointX);
    const y = Number(pointY);
    return Number.isFinite(x) && Number.isFinite(y);
  },
};

// Floating UI's React adapter rounds computed coordinates to the current
// device-pixel grid before it writes them. Do the same here. A fractional CSS
// position can rasterise identical text on different device pixels.
function roundByDPR(element, value) {
  const dpr = element.ownerDocument.defaultView?.devicePixelRatio || 1;
  return Math.round(value * dpr) / dpr;
}

// Base UI snaps both reference edges before it derives the exposed dimensions.
// Snapping only width or height can place a popup one device pixel out of sync
// when the reference starts between device-pixel boundaries.
export function snapAnchorDimensions({ x, y, width, height }, dpr) {
  return {
    width: (Math.round((x + width) * dpr) - Math.round(x * dpr)) / dpr,
    height: (Math.round((y + height) * dpr) - Math.round(y * dpr)) / dpr,
  };
}

// This is the SelectPopup alignedLeft expression from the pinned Base UI
// source. Keep it separate so fractional-position regression tests can run
// without a browser DOM.
export function alignedSelectItemLeft(positionerRect, valueRect, textRect, direction = "ltr") {
  const valueEdge = direction === "rtl" ? valueRect.right : valueRect.left;
  const textEdge = direction === "rtl" ? textRect.right : textRect.left;
  return positionerRect.left + (valueEdge - textEdge);
}

// Base UI gets Select alignment direction from its Root context. A popup can
// have a different `dir`, as the official RTL example does.
export function selectItemAlignmentDirection(positioner, _popup) {
  return positioner.dir || getComputedStyle(positioner).direction;
}

// This is the first calculation in Base UI's SelectPopup alignment effect.
// It intentionally uses the rectangle from the initial positioner pass, not
// the rectangle after the final left and height styles are applied.
export function selectItemAlignmentLayout({
  direction = "ltr",
  triggerRect,
  positionerRect,
  valueRect = null,
  textRect = null,
  viewportWidth,
  viewportHeight: clientHeight,
  scrollHeight,
  borderBottom,
  marginTop,
  marginBottom,
  minHeight,
}) {
  const viewportHeight = clientHeight - marginTop - marginBottom;
  const availableSpaceBeneathTrigger = viewportHeight - triggerRect.bottom + triggerRect.height;
  let alignedLeft = direction === "rtl"
    ? triggerRect.right - positionerRect.width
    : triggerRect.left;
  let offsetY = 0;

  if (valueRect && textRect) {
    alignedLeft = alignedSelectItemLeft(positionerRect, valueRect, textRect, direction);
    const valueCenterFromTriggerTop = valueRect.top - triggerRect.top + valueRect.height / 2;
    const textCenterFromPositionerTop = textRect.top - positionerRect.top + textRect.height / 2;
    offsetY = textCenterFromPositionerTop - valueCenterFromTriggerTop;
  }

  const idealHeight = availableSpaceBeneathTrigger + offsetY + marginBottom + borderBottom;
  const height = Math.min(viewportHeight, idealHeight);

  return {
    triggerRect,
    positionerRect,
    scrollHeight,
    minHeight,
    viewportHeight,
    idealHeight,
    maxHeight: viewportHeight - marginTop - marginBottom,
    initialHeight: Math.max(minHeight, height),
    height,
    scrollTop: idealHeight - height,
    left: clamp(
      alignedLeft,
      ITEM_ALIGN_PADDING,
      viewportWidth - ITEM_ALIGN_PADDING - positionerRect.width,
    ),
  };
}

// This is the second SelectPopup alignment calculation. It runs after the
// first calculation writes height, because clientHeight then determines the
// maximum scroll offset and the final top or bottom edge.
export function selectItemAlignmentFinal(
  layout,
  { maxScrollTop, positionerHeight, maxPopupHeight },
) {
  const isTopPositioned = layout.scrollTop >= maxScrollTop - SCROLL_EDGE_TOLERANCE;
  let height = layout.height;

  if (isTopPositioned) {
    height = Math.min(layout.viewportHeight, positionerHeight) - (layout.scrollTop - maxScrollTop);
  }

  const fallback =
    layout.triggerRect.top < ITEM_ALIGN_TRIGGER_COLLISION_THRESHOLD ||
    layout.triggerRect.bottom > layout.viewportHeight - ITEM_ALIGN_TRIGGER_COLLISION_THRESHOLD ||
    Math.ceil(height) + SCROLL_EDGE_TOLERANCE < Math.min(layout.scrollHeight, layout.minHeight);

  if (fallback) return { fallback: true };

  if (isTopPositioned) {
    const topOffset = Math.max(0, layout.viewportHeight - layout.idealHeight);
    return {
      fallback: false,
      height,
      top: positionerHeight >= layout.maxHeight ? "0px" : `${topOffset}px`,
      bottom: "",
      scrollTop: maxScrollTop,
      reachedMaxHeight: layout.initialHeight === layout.viewportHeight || height >= maxPopupHeight,
    };
  }

  return {
    fallback: false,
    height,
    top: "",
    bottom: "0px",
    scrollTop: layout.scrollTop,
    reachedMaxHeight: layout.initialHeight === layout.viewportHeight || height >= maxPopupHeight,
  };
}

function getMaxPopupHeight(popupStyles) {
  const maxHeight = popupStyles.maxHeight;
  return maxHeight.endsWith("px") ? parseFloat(maxHeight) || Infinity : Infinity;
}

function getMaxScrollTop(scroller) {
  return Math.max(0, scroller.scrollHeight - scroller.clientHeight);
}

function isHtmlElement(element) {
  return typeof HTMLElement !== "undefined" && element instanceof HTMLElement;
}

function floatingCssDimensions(element) {
  const css = getComputedStyle(element);
  let width = parseFloat(css.width) || 0;
  let height = parseFloat(css.height) || 0;
  const hasOffset = isHtmlElement(element);
  const offsetWidth = hasOffset ? element.offsetWidth : width;
  const offsetHeight = hasOffset ? element.offsetHeight : height;
  const shouldFallback = Math.round(width) !== offsetWidth || Math.round(height) !== offsetHeight;

  if (shouldFallback) {
    width = offsetWidth;
    height = offsetHeight;
  }

  return { width, height, shouldFallback };
}

export function floatingScale(element) {
  const domElement = element?.contextElement || element;
  if (!isHtmlElement(domElement)) return { x: 1, y: 1 };

  const rect = domElement.getBoundingClientRect();
  const { width, height, shouldFallback } = floatingCssDimensions(domElement);
  let x = (shouldFallback ? Math.round(rect.width) : rect.width) / width;
  let y = (shouldFallback ? Math.round(rect.height) : rect.height) / height;

  if (!x || !Number.isFinite(x)) x = 1;
  if (!y || !Number.isFinite(y)) y = 1;

  return {
    x,
    y,
  };
}

function normalizeRect(rect, scale) {
  const x = rect.x / scale.x;
  const y = rect.y / scale.y;
  const width = rect.width / scale.x;
  const height = rect.height / scale.y;

  return {
    x,
    y,
    width,
    height,
    top: y,
    right: x + width,
    bottom: y + height,
    left: x,
  };
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(value, max));
}

const TRANSFORM_STYLE_RESETS = [
  ["transform", "none"],
  ["scale", "1"],
  ["translate", "0 0"],
];

function unsetTransformStyles(element) {
  const originalStyles = {};

  for (const [property, value] of TRANSFORM_STYLE_RESETS) {
    originalStyles[property] = element.style.getPropertyValue(property);
    element.style.setProperty(property, value, "important");
  }

  return () => {
    for (const [property] of TRANSFORM_STYLE_RESETS) {
      const originalValue = originalStyles[property];
      if (originalValue) element.style.setProperty(property, originalValue);
      else element.style.removeProperty(property);
    }
  };
}
