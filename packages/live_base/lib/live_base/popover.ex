defmodule LiveBase.Popover do
  @moduledoc """
  The behavior behind anything that opens beside its trigger rather than over
  the whole page: popover, tooltip, hover card, dropdown menu, select.

  ## What is a command and what is a hook

  Opening is a `Phoenix.LiveView.JS` command, the same as everywhere else: the
  attributes flip, the focus moves, and nothing reaches the server.

  *Where* it opens is not. `data-side` reports the side the popup actually
  landed on after the browser ran out of room below; `--available-height` is
  how much room was left. Both are measurements of a layout that does not exist
  until the popup is shown, so both belong to the `LiveBase.Floating` hook —
  which is the floating position the architecture reserved a hook for.

  ## The attribute contract

  | Element | Attribute | Who sets it |
  |---|---|---|
  | trigger | `data-popup-open`, `data-pressed` | the command |
  | positioner, popup | `data-open`, `data-closed` | the command |
  | positioner, popup | `data-side`, `data-align` | the hook |
  | positioner | `data-anchor-hidden` | the hook |
  | popup | `data-starting-style`, `data-ending-style` | the hook |

  ## Dismissal

  A popover closes on Escape and on a click outside it. `phx-window-keydown`
  with `phx-key` handles Escape. `phx-click-away` holds the close command. The
  floating hook also runs that command when the owner uses `display: contents`,
  because Phoenix does not run click-away commands on an element without a
  visible rectangle. The trigger and popup are excluded from the away-click.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Popover.Floating"

  @doc "The client hook name the positioner declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook floating.js#Floating --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Floating">
      import { arrow, autoUpdate, computePosition, flip, offset, shift, size } from "@floating-ui/dom";
      const STARTING = "data-starting-style";
      const ENDING = "data-ending-style";
      function show(layers, animate = true) {
        for (const layer of layers) {
          layer.removeAttribute(ENDING);
          layer.hidden = false;
        }
        if (!animate) return;
        mark(layers, STARTING);
        layers[0].offsetHeight;
        unmark(layers, STARTING);
      }
      function hide(layers) {
        mark(layers, ENDING);
        return setTimeout(() => {
          unmark(layers, ENDING);
          for (const layer of layers) layer.hidden = true;
        }, duration(layers[0]));
      }
      function mark(layers, attribute) {
        for (const layer of layers) layer.setAttribute(attribute, "");
      }
      function unmark(layers, attribute) {
        for (const layer of layers) layer.removeAttribute(attribute);
      }
      function duration(element) {
        const style = getComputedStyle(element);
        const times = [
          style.transitionDuration,
          style.transitionDelay,
          style.animationDuration
        ];
        return Math.max(...times.map(seconds)) * 1e3;
      }
      function seconds(list) {
        return Math.max(0, ...String(list).split(",").map((value) => parseFloat(value) || 0));
      }
      const accessibilityDocuments = globalThis[Symbol.for("live_base.modal_accessibility")] ??= new WeakMap();
      function accessibilityInside(popup) {
        const document = popup.ownerDocument;
        const inside = new Set([popup]);
        const candidates = [...document.querySelectorAll("[data-lb-anchor][data-open], [data-lb-trigger][data-open], [data-phx-teleported-src]")];
        let changed;
        do {
          changed = false;
          for (const node of candidates) {
            if (inside.has(node)) continue;
            const anchor = document.getElementById(node.getAttribute("data-lb-anchor") || node.getAttribute("data-lb-trigger"));
            const source = document.getElementById(node.getAttribute("data-phx-teleported-src"));
            if ([...inside].some((target) => anchor && target.contains(anchor) || source && target.contains(source) && node.querySelector("[data-open]"))) {
              inside.add(node);
              changed = true;
            }
          }
        } while (changed);
        return inside;
      }
      function outsideNodes(document, allowed) {
        const ancestors = new Set();
        for (const target of allowed) for (let node = target; node; node = node.parentElement) ancestors.add(node);
        const outside = new Set();
        const collect = (parent) => {
          for (const node of parent.children) {
            if (node.matches("script, template") || allowed.has(node)) continue;
            if (ancestors.has(node) || document.defaultView.getComputedStyle(node).display === "contents") collect(node);
            else outside.add(node);
          }
        };
        collect(document.body);
        return outside;
      }
      function refreshAccessibility(state, records = []) {
        const pending = [...records, ...state.observer.takeRecords()];
        for (const record of pending) if (record.attributeName === "aria-hidden" && state.hidden.has(record.target)) state.hidden.set(record.target, record.target.getAttribute("aria-hidden"));
        state.observer.disconnect();
        const front = state.owners.findLast((owner) => owner.element.isConnected && owner.element.hasAttribute("data-open"));
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
        if (state.owners.length) state.observer.observe(state.document.body, {
          subtree: true,
          childList: true,
          attributes: true,
          attributeFilter: [
            "aria-hidden",
            "aria-live",
            "data-open",
            "hidden",
            "class",
            "style"
          ]
        });
      }
      function holdAccessibility(element, inside = () => accessibilityInside(element)) {
        const document = element.ownerDocument;
        let state = accessibilityDocuments.get(document);
        if (!state) {
          state = {
            document,
            owners: [],
            hidden: new Map()
          };
          state.observer = new document.defaultView.MutationObserver((records) => refreshAccessibility(state, records));
          accessibilityDocuments.set(document, state);
        }
        const lease = {
          element,
          inside,
          state,
          released: false
        };
        state.owners.push(lease);
        refreshAccessibility(state);
        return lease;
      }
      function releaseAccessibility(lease) {
        if (!lease || lease.released) return;
        lease.released = true;
        const state = lease.state;
        state.owners = state.owners.filter((owner) => owner !== lease);
        refreshAccessibility(state);
        if (state.owners.length) return;
        state.observer.disconnect();
        accessibilityDocuments.delete(state.document);
      }
      const ORIGIN = {
        top: "bottom",
        bottom: "top",
        left: "right",
        right: "left"
      };
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
        "[tabindex]:not([tabindex='-1'])"
      ].join(",");
      const Floating = {
        mounted() {
          this.anchor = document.getElementById(this.el.getAttribute("data-lb-anchor"));
          this.openedByKeyboard = false;
          this.markPointerOpen = () => this.openedByKeyboard = false;
          this.markKeyboardOpen = (event) => {
            if ([
              "Enter",
              " ",
              "ArrowDown",
              "ArrowUp"
            ].includes(event.key)) this.openedByKeyboard = true;
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
            attributeFilter: [
              "data-open",
              "data-lb-side",
              "data-lb-semantic-side",
              "data-lb-align"
            ]
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
          this.requestedSemanticSide = this.el.getAttribute("data-lb-semantic-side") || this.requestedSide;
          this.requestedAlign = this.el.getAttribute("data-lb-align") || "center";
        },
        takeFocus() {
          if (!this.el.hasAttribute("data-lb-autofocus")) return;
          this.returnTo = document.activeElement;
          const highlighted = this.popup.hasAttribute("data-lb-initial-highlight") ? this.popup.querySelector("[role='option'][data-selected]:not([data-disabled])") || this.popup.querySelector("[role='option']:not([data-disabled])") : null;
          if (highlighted) highlighted.setAttribute("data-highlighted", "");
          const firstMenuItem = this.popup.matches("[data-lb-roving='menuitem']") ? this.popup.querySelector("[role^='menuitem']:not([data-disabled])") : null;
          const activeMenuItem = this.openedByKeyboard ? firstMenuItem : null;
          if (activeMenuItem) activeMenuItem.setAttribute("data-highlighted", "");
          (highlighted || activeMenuItem || this.popup.querySelector("[autofocus]") || this.popup.querySelector(FOCUSABLE) || this.popup).focus({ preventScroll: true });
        },
        returnFocus() {
          if (this.el.hasAttribute("data-lb-return-focus-to-trigger")) this.anchor?.focus({ preventScroll: true });
          else if (!this.el.hasAttribute("data-lb-no-return-focus") && this.returnTo && this.popup.contains(document.activeElement)) (this.el.hasAttribute("data-lb-return-focus-to-wrapper") ? this.anchor : this.returnTo)?.focus({ preventScroll: true });
          this.returnTo = null;
        },
        attach() {
          if (!this.anchor || this.cleanup) return;
          this.cleanup = autoUpdate(this.reference(), this.el, () => this.place());
          if (this.el.getAttribute("data-lb-accessibility") === "modal") this.accessibilityLease = holdAccessibility(this.el, () => this.accessibilityInside());
          if (this.dismissOwner) document.addEventListener("click", this.dismissOutside);
        },
        detach() {
          releaseAccessibility(this.accessibilityLease);
          this.accessibilityLease = null;
          document.removeEventListener("click", this.dismissOutside);
          this.cleanup?.();
          this.cleanup = null;
        },
        findDismissOwner() {
          const ownerId = this.el.getAttribute("data-lb-dismiss-owner");
          const owner = ownerId ? document.getElementById(ownerId) : this.el.closest("[data-lb-dismiss-command], [phx-click-away]");
          if (!owner) return null;
          if (owner === this.el) return owner;
          if (this.el.getAttribute("data-lb-anchor") !== `${owner.id}-trigger`) return null;
          return owner;
        },
        onDismissOutside(event) {
          if (!this.el.hasAttribute("data-open")) return;
          if (this.anchor?.contains(event.target) || this.owns(event.target)) return;
          const command = this.dismissOwner?.getAttribute("data-lb-dismiss-command") || this.dismissOwner?.getAttribute("phx-click-away");
          if (command) this.liveSocket.execJS(this.dismissOwner, command, "click");
        },
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
          for (const popup of this.el.ownerDocument.querySelectorAll("[data-lb-popup]")) if (this.owns(popup)) inside.add(popup);
          return inside;
        },
        async place() {
          const pointReference = this.hasPointReference();
          const middleware = [
            offset(this.offsetOptions()),
            flip({
              padding: this.flipPadding(),
              mainAxis: !pointReference
            }),
            shift({
              padding: 5,
              crossAxis: pointReference
            }),
            size({
              padding: 5,
              apply: ({ availableWidth, availableHeight, rects }) => {
                const viewport = this.el.ownerDocument.documentElement;
                const width = pointReference ? viewport.clientWidth - 10 : availableWidth;
                const height = pointReference ? viewport.clientHeight - 10 : availableHeight;
                const anchor = snapAnchorDimensions(rects.reference, this.el.ownerDocument.defaultView?.devicePixelRatio || 1);
                this.el.style.setProperty("--anchor-width", `${anchor.width}px`);
                this.el.style.setProperty("--anchor-height", `${anchor.height}px`);
                this.el.style.setProperty("--available-width", `${width}px`);
                this.el.style.setProperty("--available-height", `${height}px`);
              }
            })
          ];
          if (this.arrow) middleware.push(arrow({
            element: this.arrow,
            padding: 4
          }));
          let { x, y, placement, middlewareData } = await computePosition(this.reference(), this.el, {
            placement: this.placement(),
            strategy: "fixed",
            middleware
          });
          const [side, align = "center"] = placement.split("-");
          this.placeInitialItemAlignmentPosition(x, y);
          const aligned = this.itemAlignedPosition(x, y);
          const positioned = aligned.itemAligned ? aligned : this.el.hasAttribute("data-lb-fractional") ? aligned : {
            x: roundByDPR(this.el, aligned.x),
            y: roundByDPR(this.el, aligned.y)
          };
          if (aligned.itemAligned) {} else if (this.el.hasAttribute("data-lb-fractional")) Object.assign(this.el.style, {
            position: "fixed",
            left: `${positioned.x}px`,
            top: `${positioned.y}px`,
            bottom: "",
            marginTop: "",
            marginBottom: "",
            transform: "none"
          });
          else Object.assign(this.el.style, {
            position: "fixed",
            left: "0px",
            top: "0px",
            bottom: "",
            marginTop: "",
            marginBottom: "",
            transform: `translate(${positioned.x}px, ${positioned.y}px)`
          });
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
            bottom: ""
          });
          this.arrow.setAttribute("data-side", side);
          this.arrow.setAttribute("data-align", align);
        },
        semanticSide(actualSide) {
          if (!["inline-start", "inline-end"].includes(this.requestedSemanticSide)) return actualSide;
          if (actualSide === this.requestedSide) return this.requestedSemanticSide;
          return this.requestedSemanticSide === "inline-start" ? "inline-end" : "inline-start";
        },
        itemAlignedPosition(x, y) {
          if (!this.el.hasAttribute("data-lb-align-item") || this.itemAlignmentDisabled) return {
            x,
            y
          };
          const item = this.popup.querySelector("[role='option'][data-selected]") || this.popup.querySelector("[role='option']:not([data-disabled])");
          if (!item) return {
            x,
            y
          };
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
              minHeight
            });
            Object.assign(this.el.style, {
              left: `${layout.left}px`,
              height: `${layout.height}px`,
              maxHeight: "none",
              marginTop: `${marginTop}px`,
              marginBottom: `${marginBottom}px`,
              transform: "none"
            });
            this.popup.style.height = "100%";
            const final = selectItemAlignmentFinal(layout, {
              maxScrollTop: getMaxScrollTop(this.popup),
              positionerHeight: positionerRect.height,
              maxPopupHeight
            });
            if (final.fallback) {
              this.itemAlignmentDisabled = true;
              this.clearItemAlignmentStyles();
              return {
                x,
                y
              };
            }
            this.el.style.height = `${final.height}px`;
            this.el.style.top = final.top;
            this.el.style.bottom = final.bottom;
            this.popup.scrollTop = final.scrollTop;
            if (textRect) {
              const textCenterY = textRect.top + textRect.height / 2;
              const originY = clamp(positionerRect.height > 0 ? (textCenterY - positionerRect.top) / positionerRect.height * 100 : 50, 0, 100);
              this.popup.style.setProperty("--transform-origin", `50% ${originY}%`);
            }
            return {
              x: layout.left,
              y: final.height,
              itemAligned: true
            };
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
            transform: `translate(${x}px, ${y}px)`
          });
        },
        clearItemAlignmentStyles() {
          Object.assign(this.el.style, {
            height: "",
            maxHeight: "",
            marginTop: "",
            marginBottom: "",
            bottom: ""
          });
          this.popup.style.height = "";
        },
        syncScrollArrows() {
          const up = this.popup.querySelector("[data-slot='select-scroll-up-button']");
          const down = this.popup.querySelector("[data-slot='select-scroll-down-button']");
          if (!up || !down) return;
          up.hidden = this.popup.scrollTop <= .5;
          down.hidden = this.popup.scrollTop + this.popup.clientHeight >= this.popup.scrollHeight - .5;
        },
        placement() {
          const side = this.requestedSide;
          const align = this.requestedAlign;
          return align === "center" ? side : `${side}-${align}`;
        },
        crossAxisOffset() {
          return Number(this.el.getAttribute("data-lb-align-offset")) || 0;
        },
        offsetOptions() {
          const alignAxis = this.crossAxisOffset();
          return {
            mainAxis: Number(this.el.getAttribute("data-lb-offset")) || 0,
            crossAxis: alignAxis,
            alignmentAxis: alignAxis
          };
        },
        flipPadding() {
          const padding = {
            top: 6,
            right: 6,
            bottom: 6,
            left: 6
          };
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
          return { getBoundingClientRect: () => ({
            x,
            y,
            top: y,
            right: x,
            bottom: y,
            left: x,
            width: 0,
            height: 0
          }) };
        },
        hasPointReference() {
          const pointX = this.el.getAttribute("data-lb-point-x");
          const pointY = this.el.getAttribute("data-lb-point-y");
          if (pointX == null || pointY == null) return false;
          const x = Number(pointX);
          const y = Number(pointY);
          return Number.isFinite(x) && Number.isFinite(y);
        }
      };
      function roundByDPR(element, value) {
        const dpr = element.ownerDocument.defaultView?.devicePixelRatio || 1;
        return Math.round(value * dpr) / dpr;
      }
      function snapAnchorDimensions({ x, y, width, height }, dpr) {
        return {
          width: (Math.round((x + width) * dpr) - Math.round(x * dpr)) / dpr,
          height: (Math.round((y + height) * dpr) - Math.round(y * dpr)) / dpr
        };
      }
      function alignedSelectItemLeft(positionerRect, valueRect, textRect, direction = "ltr") {
        const valueEdge = direction === "rtl" ? valueRect.right : valueRect.left;
        const textEdge = direction === "rtl" ? textRect.right : textRect.left;
        return positionerRect.left + (valueEdge - textEdge);
      }
      function selectItemAlignmentDirection(positioner, _popup) {
        return positioner.dir || getComputedStyle(positioner).direction;
      }
      function selectItemAlignmentLayout({ direction = "ltr", triggerRect, positionerRect, valueRect = null, textRect = null, viewportWidth, viewportHeight: clientHeight, scrollHeight, borderBottom, marginTop, marginBottom, minHeight }) {
        const viewportHeight = clientHeight - marginTop - marginBottom;
        const availableSpaceBeneathTrigger = viewportHeight - triggerRect.bottom + triggerRect.height;
        let alignedLeft = direction === "rtl" ? triggerRect.right - positionerRect.width : triggerRect.left;
        let offsetY = 0;
        if (valueRect && textRect) {
          alignedLeft = alignedSelectItemLeft(positionerRect, valueRect, textRect, direction);
          const valueCenterFromTriggerTop = valueRect.top - triggerRect.top + valueRect.height / 2;
          offsetY = textRect.top - positionerRect.top + textRect.height / 2 - valueCenterFromTriggerTop;
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
          left: clamp(alignedLeft, ITEM_ALIGN_PADDING, viewportWidth - ITEM_ALIGN_PADDING - positionerRect.width)
        };
      }
      function selectItemAlignmentFinal(layout, { maxScrollTop, positionerHeight, maxPopupHeight }) {
        const isTopPositioned = layout.scrollTop >= maxScrollTop - SCROLL_EDGE_TOLERANCE;
        let height = layout.height;
        if (isTopPositioned) height = Math.min(layout.viewportHeight, positionerHeight) - (layout.scrollTop - maxScrollTop);
        if (layout.triggerRect.top < ITEM_ALIGN_TRIGGER_COLLISION_THRESHOLD || layout.triggerRect.bottom > layout.viewportHeight - ITEM_ALIGN_TRIGGER_COLLISION_THRESHOLD || Math.ceil(height) + SCROLL_EDGE_TOLERANCE < Math.min(layout.scrollHeight, layout.minHeight)) return { fallback: true };
        if (isTopPositioned) {
          const topOffset = Math.max(0, layout.viewportHeight - layout.idealHeight);
          return {
            fallback: false,
            height,
            top: positionerHeight >= layout.maxHeight ? "0px" : `${topOffset}px`,
            bottom: "",
            scrollTop: maxScrollTop,
            reachedMaxHeight: layout.initialHeight === layout.viewportHeight || height >= maxPopupHeight
          };
        }
        return {
          fallback: false,
          height,
          top: "",
          bottom: "0px",
          scrollTop: layout.scrollTop,
          reachedMaxHeight: layout.initialHeight === layout.viewportHeight || height >= maxPopupHeight
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
        return {
          width,
          height,
          shouldFallback
        };
      }
      function floatingScale(element) {
        const domElement = element?.contextElement || element;
        if (!isHtmlElement(domElement)) return {
          x: 1,
          y: 1
        };
        const rect = domElement.getBoundingClientRect();
        const { width, height, shouldFallback } = floatingCssDimensions(domElement);
        let x = (shouldFallback ? Math.round(rect.width) : rect.width) / width;
        let y = (shouldFallback ? Math.round(rect.height) : rect.height) / height;
        if (!x || !Number.isFinite(x)) x = 1;
        if (!y || !Number.isFinite(y)) y = 1;
        return {
          x,
          y
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
          left: x
        };
      }
      function clamp(value, min, max) {
        return Math.max(min, Math.min(value, max));
      }
      const TRANSFORM_STYLE_RESETS = [
        ["transform", "none"],
        ["scale", "1"],
        ["translate", "0 0"]
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
      export default Floating;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc "The id of the button that opens a popover."
  def trigger_id(popover), do: "#{popover}-trigger"

  @doc "The id of the element the popup is positioned against."
  def positioner_id(popover), do: "#{popover}-positioner"

  @doc "The id of the popup itself."
  def popup_id(popover), do: "#{popover}-popup"

  @doc """
  Opens a popover.

  The focus moves into the popup for a popover and a menu, and stays where it
  is for a tooltip. `:focus` says which, because a tooltip that stole the focus
  would be a tooltip nobody could type past.
  """
  def open(js \\ %JS{}, popover, opts \\ []) do
    trigger_id = Keyword.get(opts, :trigger_id, trigger_id(popover))

    js
    |> JS.set_attribute({"data-popup-open", ""}, to: "##{trigger_id}")
    |> JS.set_attribute({"data-pressed", ""}, to: "##{trigger_id}")
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{trigger_id}")
    |> JS.remove_attribute("hidden", to: layers(popover))
    |> JS.set_attribute({"data-open", ""}, to: layers(popover))
    |> JS.remove_attribute("data-closed", to: layers(popover))
    |> then(&if Keyword.get(opts, :focus, true), do: focus(&1, popover), else: &1)
  end

  # The popup itself, not its first control. A popover may hold nothing
  # focusable at all, and a dialog that opens without moving the focus leaves a
  # screen reader on the page behind it.
  defp focus(js, popover), do: JS.focus(js, to: "##{popup_id(popover)}")

  @doc "Closes a popover."
  def close(js \\ %JS{}, popover, opts \\ []) do
    trigger_id = Keyword.get(opts, :trigger_id, trigger_id(popover))

    js
    |> JS.remove_attribute("data-popup-open", to: "##{trigger_id}")
    |> JS.remove_attribute("data-pressed", to: "##{trigger_id}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{trigger_id}")
    |> JS.remove_attribute("data-open", to: layers(popover))
    |> JS.set_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc """
  Opens a closed popover and closes an open one.

  The flip reads the trigger's own state, so the server never has to know which
  way round it is.
  """
  def toggle(js \\ %JS{}, popover, opts \\ []) do
    trigger_id = Keyword.get(opts, :trigger_id, trigger_id(popover))

    js
    |> JS.toggle_attribute({"data-popup-open", ""}, to: "##{trigger_id}")
    |> JS.toggle_attribute({"data-pressed", ""}, to: "##{trigger_id}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{trigger_id}")
    |> JS.remove_attribute("hidden", to: layers(popover))
    |> JS.toggle_attribute({"data-open", ""}, to: layers(popover))
    |> JS.toggle_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc "Opens a tooltip without giving its trigger disclosure semantics."
  def tooltip_toggle(js \\ %JS{}, popover, opts \\ []) do
    trigger_id = Keyword.get(opts, :trigger_id, trigger_id(popover))

    js
    |> JS.toggle_attribute({"data-popup-open", ""}, to: "##{trigger_id}")
    |> JS.toggle_attribute({"data-pressed", ""}, to: "##{trigger_id}")
    |> JS.remove_attribute("hidden", to: layers(popover))
    |> JS.toggle_attribute({"data-open", ""}, to: layers(popover))
    |> JS.toggle_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc "Closes a tooltip without leaving disclosure state on its trigger."
  def tooltip_close(js \\ %JS{}, popover, opts \\ []) do
    trigger_id = Keyword.get(opts, :trigger_id, trigger_id(popover))

    js
    |> JS.remove_attribute("data-popup-open", to: "##{trigger_id}")
    |> JS.remove_attribute("data-pressed", to: "##{trigger_id}")
    |> JS.remove_attribute("data-open", to: layers(popover))
    |> JS.set_attribute({"data-closed", ""}, to: layers(popover))
  end

  @doc """
  Closes a popover when the reader clicks outside it.

  Written for `phx-click-away` on the popup. The trigger's own click is not an
  away-click: it toggles, and closing here as well would undo it in the same
  gesture.
  """
  def dismiss(js \\ %JS{}, popover, opts \\ []), do: close(js, popover, opts)

  @doc "Marks the attributes the client owns so a server render does not close it."
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :trigger),
    do:
      JS.ignore_attributes(
        js,
        ["aria-controls", "aria-expanded", "data-popup-open", "data-pressed"],
        []
      )

  def owned_attributes(js, part) when part in [:positioner, :popup] do
    JS.ignore_attributes(
      js,
      [
        "data-open",
        "data-closed",
        "data-side",
        "data-align",
        "data-anchor-hidden",
        "data-starting-style",
        "data-ending-style",
        "hidden",
        "style"
      ],
      []
    )
  end

  defp layers(popover), do: "##{positioner_id(popover)}, ##{popup_id(popover)}"
end
