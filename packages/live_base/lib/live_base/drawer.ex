defmodule LiveBase.Drawer do
  @moduledoc """
  The browser behavior behind a drawer: swipes, snap points, nested drawers,
  and a viewport that stays until its closing transition ends.

  Opening and closing are `LiveBase.Dialog` commands. This hook adds the
  gestures a `JS` command cannot express.
  """

  use Phoenix.Component

  @doc "The client hook name the drawer popup declares in `phx-hook`."
  def hook, do: "LiveBase.Drawer.Drawer"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook drawer.js#Drawer --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Drawer">
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
      const OPEN$1 = "data-open";
      const FOCUSABLE = [
        "a[href]",
        "button:not([disabled])",
        "input:not([disabled]):not([type='hidden'])",
        "select:not([disabled])",
        "textarea:not([disabled])",
        "[tabindex]:not([tabindex='-1'])"
      ].join(",");
      const modalDocuments = globalThis[Symbol.for("live_base.modal_stack")] ??= new WeakMap();
      function frontModal(state) {
        return state.owners.findLast((owner) => owner.el.isConnected && owner.el.hasAttribute(OPEN$1));
      }
      function refreshModal(state) {
        state.observer.disconnect();
        const front = frontModal(state);
        state.inside = front ? accessibilityInside(front.el) : new Set();
        if (state.owners.length) state.observer.observe(state.document.body, {
          subtree: true,
          childList: true,
          attributes: true,
          attributeFilter: [
            "aria-live",
            "data-open",
            "hidden",
            "class",
            "style"
          ]
        });
      }
      function holdModal(owner) {
        const document = owner.el.ownerDocument;
        let state = modalDocuments.get(document);
        if (!state) {
          state = {
            document,
            owners: [],
            inside: new Set(),
            overflow: document.body.style.overflow,
            padding: document.body.style.paddingRight
          };
          state.observer = new document.defaultView.MutationObserver(() => refreshModal(state));
          modalDocuments.set(document, state);
          const scrollbar = document.defaultView.innerWidth - document.documentElement.clientWidth;
          document.body.style.overflow = "hidden";
          if (scrollbar > 0) document.body.style.paddingRight = `${scrollbar}px`;
        }
        state.owners.push(owner);
        owner.accessibilityLease = holdAccessibility(owner.el);
        refreshModal(state);
        return state;
      }
      function releaseModal(owner, state) {
        releaseAccessibility(owner.accessibilityLease);
        owner.accessibilityLease = null;
        state.owners = state.owners.filter((candidate) => candidate !== owner);
        refreshModal(state);
        if (state.owners.length) return;
        state.document.body.style.overflow = state.overflow;
        state.document.body.style.paddingRight = state.padding;
        modalDocuments.delete(state.document);
      }
      const Overlay = {
        mounted() {
          this.modal = this.el.hasAttribute("data-lb-modal");
          this.open = this.el.hasAttribute(OPEN$1);
          this.onKeydown = (event) => this.keydown(event);
          this.onFocusIn = (event) => this.focusin(event);
          this.el.addEventListener("focusin", this.onFocusIn);
          if (this.open) this.enter(false);
          this.observer = new MutationObserver(() => this.stateChanged());
          this.observer.observe(this.el, {
            attributes: true,
            attributeFilter: [OPEN$1]
          });
        },
        destroyed() {
          this.observer?.disconnect();
          clearTimeout(this.timer);
          this.release();
          this.el.removeEventListener("focusin", this.onFocusIn);
        },
        layers() {
          const backdrop = this.el.getAttribute("data-lb-backdrop");
          const behind = backdrop && document.getElementById(backdrop);
          return behind ? [this.el, behind] : [this.el];
        },
        stateChanged() {
          const open = this.el.hasAttribute(OPEN$1);
          if (open === this.open) return;
          this.open = open;
          open ? this.enter(true) : this.leave();
        },
        enter(animate) {
          clearTimeout(this.timer);
          show(this.layers(), animate);
          this.hold();
        },
        leave() {
          clearTimeout(this.timer);
          this.release();
          this.timer = hide(this.layers());
        },
        hold() {
          if (!this.modal || this.held) return;
          this.held = holdModal(this);
          this.el.ownerDocument.addEventListener("keydown", this.onKeydown, true);
        },
        release() {
          if (!this.held) return;
          releaseModal(this, this.held);
          this.held = null;
          this.el.ownerDocument.removeEventListener("keydown", this.onKeydown, true);
        },
        focusin(event) {
          if (this.el.hasAttribute(OPEN$1)) return;
          const outside = event.relatedTarget;
          if (outside?.isConnected && !this.el.contains(outside) && !outside.closest("[hidden], [inert], [aria-hidden='true'], [role='dialog'][data-closed], [role='alertdialog'][data-closed]")) outside.focus({ preventScroll: true });
          if (this.el.contains(this.el.ownerDocument.activeElement)) event.target.blur();
        },
        keydown(event) {
          if (event.key !== "Tab" || event.defaultPrevented || frontModal(this.held) !== this) return;
          const focusable = [...new Set([...this.held.inside].flatMap((target) => [...target.querySelectorAll(FOCUSABLE)]))].filter((el) => el.tabIndex >= 0 && el.offsetParent && !el.closest("[aria-hidden='true'], [inert]"));
          if (focusable.length === 0) return event.preventDefault();
          const first = focusable[0];
          const last = focusable[focusable.length - 1];
          const active = this.el.ownerDocument.activeElement;
          if (![...this.held.inside].some((target) => target.contains(active))) {
            event.preventDefault();
            first.focus();
          } else if (event.shiftKey && active === first) {
            event.preventDefault();
            last.focus();
          } else if (!event.shiftKey && active === last) {
            event.preventDefault();
            first.focus();
          }
        }
      };
      const OPEN = "data-open";
      const SWIPING = "data-swiping";
      const MOVEMENT_X = "--drawer-swipe-movement-x";
      const MOVEMENT_Y = "--drawer-swipe-movement-y";
      const PROGRESS = "--drawer-swipe-progress";
      const STRENGTH = "--drawer-swipe-strength";
      const SNAP_OFFSET = "--drawer-snap-point-offset";
      const Drawer = {
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
          const nested = [...document.querySelectorAll("[data-slot='drawer-popup'][data-lb-parent]")].some((drawer) => hasDrawerAncestor(drawer, this.el));
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
          const progress = this.resolvedSnapPoints.length === 1 ? 0 : 1 - this.activeSnapIndex / (this.resolvedSnapPoints.length - 1);
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
            movement: 0
          };
          this.el.setPointerCapture?.(event.pointerId);
          window.addEventListener("pointermove", this.onPointerMove, { passive: false });
          window.addEventListener("pointerup", this.onPointerUp);
          window.addEventListener("pointercancel", this.onPointerUp);
        },
        pointerMove(event) {
          if (!this.drag || event.pointerId !== this.drag.id) return;
          const direction = this.el.getAttribute("data-swipe-direction") || "down";
          const raw = direction === "down" || direction === "up" ? event.clientY - this.drag.y : event.clientX - this.drag.x;
          const movement = this.resolvedSnapPoints?.length > 1 && (direction === "down" || direction === "up") ? raw : closingMovement(direction, raw);
          if (Math.abs(movement) < 2) return;
          event.preventDefault();
          this.drag.movement = movement;
          this.markSwiping(true);
          const axisVariable = direction === "down" || direction === "up" ? MOVEMENT_Y : MOVEMENT_X;
          this.el.style.setProperty(axisVariable, `${movement}px`);
          this.setLayerVariable(axisVariable, `${movement}px`);
          const size = direction === "down" || direction === "up" ? this.el.getBoundingClientRect().height : this.el.getBoundingClientRect().width;
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
          const size = direction === "down" || direction === "up" ? this.el.getBoundingClientRect().height : this.el.getBoundingClientRect().width;
          this.setLayerVariable(STRENGTH, String(Math.max(.1, Math.min(1, velocity))));
          this.removePointerListeners();
          this.drag = null;
          this.markSwiping(false);
          markAncestorSwiping(this.el, false);
          if (this.resolvedSnapPoints?.length > 1 && (direction === "down" || direction === "up")) {
            const signedMovement = movement * (direction === "down" ? 1 : -1);
            const moved = Math.abs(movement) > 40 || velocity > .5;
            const next = moved ? signedMovement > 0 ? this.activeSnapIndex - 1 : this.activeSnapIndex + 1 : this.activeSnapIndex;
            if (moved && next < 0) {
              this.closeDrawer();
              return;
            }
            this.resetSwipe();
            this.applySnapPoint(next);
            return;
          }
          if (Math.abs(movement) > size * .25 || velocity > .5) this.closeDrawer();
          else this.resetSwipe();
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
          for (const layer of this.layers()) active ? layer.setAttribute(SWIPING, "") : layer.removeAttribute(SWIPING);
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
          if (event.key !== "Escape" || !this.open || event.defaultPrevented || !this.el.hasAttribute("data-lb-dismissible")) return;
          if (frontmostOpenDrawer() !== this.el) return;
          event.preventDefault();
          this.closeDrawer();
        },
        outsidePointerDown(event) {
          if (!this.open || !this.el.hasAttribute("data-lb-dismissible") || this.el.hasAttribute("data-lb-disable-pointer-dismissal")) return;
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
        }
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
        return points.map((point) => {
          let height = null;
          if (typeof point === "number") height = point <= 1 ? point * viewportHeight : point;
          else if (typeof point === "string" && point.endsWith("rem")) height = parseFloat(point) * rootFontSize;
          else if (typeof point === "string" && point.endsWith("px")) height = parseFloat(point);
          if (!Number.isFinite(height)) return null;
          const clamped = Math.max(0, Math.min(height, popupHeight, viewportHeight));
          return {
            height: clamped,
            offset: Math.max(0, popupHeight - clamped)
          };
        }).filter(Boolean);
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
        const state = new Map(drawers.map((drawer) => [drawer, {
          count: 0,
          frontmost: null
        }]));
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
            drawer.style.setProperty("--drawer-frontmost-height", entry.frontmost.style.getPropertyValue("--drawer-height") || `${entry.frontmost.offsetHeight}px`);
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
          active ? ancestor.setAttribute("data-nested-drawer-swiping", "") : ancestor.removeAttribute("data-nested-drawer-swiping");
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
      export default Drawer;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
