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
//   data-lb-align      the alignment asked for
//   data-lb-offset     the gap between anchor and popup, in pixels
//   data-lb-align-offset  the cross-axis adjustment, in pixels
//   data-lb-popup      on the element inside it that is styled and animated
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

const ORIGIN = { top: "bottom", bottom: "top", left: "right", right: "left" };

export const Floating = {
  mounted() {
    this.anchor = document.getElementById(this.el.getAttribute("data-lb-anchor"));
    this.arrow = this.el.querySelector("[data-lb-arrow]");
    this.open = this.el.hasAttribute("data-open");
    this.popup = this.el.querySelector("[data-lb-popup]") || this.el;

    if (this.open) {
      show(this.layers(), false);
      this.attach();
    }

    this.observer = new MutationObserver(() => this.stateChanged());
    this.observer.observe(this.el, { attributes: true, attributeFilter: ["data-open"] });
  },

  destroyed() {
    this.detach();
    clearTimeout(this.timer);
    this.observer?.disconnect();
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
      show(this.layers());
      this.attach();
      this.takeFocus();
    } else {
      this.detach();
      this.returnFocus();
      this.timer = hide(this.layers());
    }
  },

  // The focus moves once the popup is on the page, which is why it is the
  // hook's to do: a `JS` command runs before `hidden` has been removed, and a
  // hidden element cannot be focused.
  takeFocus() {
    if (!this.el.hasAttribute("data-lb-autofocus")) return;
    this.returnTo = document.activeElement;
    (this.popup.querySelector("[autofocus]") || this.popup).focus();
  },

  returnFocus() {
    if (this.returnTo && this.popup.contains(document.activeElement)) this.returnTo.focus();
    this.returnTo = null;
  },

  // While it is open the position is kept current: the page can scroll, the
  // window can resize, and the anchor can move under it.
  attach() {
    if (!this.anchor || this.cleanup) return;
    this.cleanup = autoUpdate(this.anchor, this.el, () => this.place());
  },

  detach() {
    this.cleanup?.();
    this.cleanup = null;
  },

  async place() {
    const middleware = [
      offset({
        mainAxis: Number(this.el.getAttribute("data-lb-offset")) || 0,
        crossAxis: Number(this.el.getAttribute("data-lb-align-offset")) || 0,
      }),
      flip(),
      shift({ padding: 8 }),
      size({
        padding: 8,
        apply: ({ availableWidth, availableHeight, rects }) => {
          this.el.style.setProperty("--anchor-width", `${rects.reference.width}px`);
          this.el.style.setProperty("--anchor-height", `${rects.reference.height}px`);
          this.el.style.setProperty("--available-width", `${availableWidth}px`);
          this.el.style.setProperty("--available-height", `${availableHeight}px`);
        },
      }),
    ];

    if (this.arrow) middleware.push(arrow({ element: this.arrow, padding: 4 }));

    const { x, y, placement, middlewareData } = await computePosition(this.anchor, this.el, {
      placement: this.placement(),
      strategy: "fixed",
      middleware,
    });

    Object.assign(this.el.style, { position: "fixed", left: `${x}px`, top: `${y}px` });

    const [side, align = "center"] = placement.split("-");
    this.el.setAttribute("data-side", side);
    this.el.setAttribute("data-align", align);
    this.el.style.setProperty("--transform-origin", ORIGIN[side]);

    this.el.toggleAttribute("data-anchor-hidden", !!middlewareData.hide?.referenceHidden);
    this.placeArrow(middlewareData.arrow, side);
  },

  placeArrow(position, side) {
    if (!this.arrow || !position) return;

    const { x, y } = position;
    Object.assign(this.arrow.style, {
      position: "absolute",
      left: x == null ? "" : `${x}px`,
      top: y == null ? "" : `${y}px`,
      [ORIGIN[side]]: "0",
    });

    this.arrow.setAttribute("data-side", side);
  },

  // What was asked for. Where it ends up is what `flip` decides, and that is
  // what `data-side` reports.
  placement() {
    const side = this.el.getAttribute("data-lb-side") || "bottom";
    const align = this.el.getAttribute("data-lb-align") || "center";
    return align === "center" ? side : `${side}-${align}`;
  },
};
