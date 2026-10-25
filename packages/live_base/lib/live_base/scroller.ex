defmodule LiveBase.Scroller do
  @moduledoc """
  The behavior behind a scroll area whose scrollbar the style sheet can reach.

  ## What the hook owns

  All of it, and that is unusual here. Every other module in this package puts
  the decision in a `Phoenix.LiveView.JS` command on the server and keeps the
  hook for the one thing a command cannot express. A scroll area has no
  decision: it has a measurement, and then another one every time the reader
  moves.

  How much there is to scroll, how far down they are, how tall the thumb should
  be — the server knows none of it and never will. So the hook measures and
  writes, and the class strings shadcn already wrote read what it writes.

  ## The attribute contract

  | Attribute | When |
  |---|---|
  | `data-has-overflow-x` | there is more content than fits, across |
  | `data-has-overflow-y` | the same, down |
  | `data-overflow-x-start` | content is hidden off the start edge |
  | `data-overflow-x-end` | …off the end edge |
  | `data-overflow-y-start` | the same, above |
  | `data-overflow-y-end` | the same, below |
  | `data-scrolling` | while the reader is scrolling, and briefly after |
  | `data-pending-scroll` | before a message list reaches its opening position |

  And six CSS variables: `--scroll-area-thumb-height` and `-width` for the size
  of the thumb, and `--scroll-area-overflow-{x,y}-{start,end}` for how far along
  it is. Base UI documents every one of them, which is why the generated
  component can be held to them.

  ## Why the thumb is never moved directly

  Dragging it scrolls the viewport; scrolling the viewport moves it. One
  direction of travel, so the two can never disagree — a thumb that was moved
  by a drag *and* by the scroll it caused would fight itself at the ends.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Scroller.Scroller"

  @doc "The client hook name the root declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook scroller.js#Scroller --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Scroller">
      import { animate } from "motion";
      const running = new WeakMap();
      const ACTIVE_ENTRY_ATTRIBUTE = "data-lb-message-entry-active";
      const MESSAGE_ANIMATION_PRESETS = Object.freeze({
        fade: {
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          transition: {
            duration: .22,
            ease: "easeOut"
          }
        },
        "slide-up": {
          initial: {
            opacity: 0,
            y: 10
          },
          animate: {
            opacity: 1,
            y: 0
          },
          transition: {
            duration: .26,
            ease: [
              .16,
              1,
              .3,
              1
            ]
          }
        },
        "slide-side": {
          initial: {
            opacity: 0,
            x: 18
          },
          animate: {
            opacity: 1,
            x: 0
          },
          transition: {
            duration: .28,
            ease: [
              .16,
              1,
              .3,
              1
            ]
          }
        },
        pop: {
          initial: {
            opacity: 0,
            scale: .94,
            y: 6,
            originX: 1,
            originY: 1
          },
          animate: {
            opacity: 1,
            y: 0,
            scale: 1
          },
          transition: {
            type: "spring",
            stiffness: 500,
            damping: 34,
            mass: .7
          }
        },
        "spring-bounce": {
          initial: {
            opacity: 0,
            y: 12,
            scale: .96
          },
          animate: {
            opacity: 1,
            y: 0,
            scale: 1
          },
          transition: {
            type: "spring",
            stiffness: 520,
            damping: 30,
            mass: .7
          }
        },
        "blur-fade": {
          initial: {
            opacity: 0,
            filter: "blur(4px)",
            y: 6
          },
          animate: {
            opacity: 1,
            y: 0,
            filter: "blur(0px)"
          },
          transition: {
            duration: .28,
            ease: "easeOut"
          }
        },
        "scale-fade": {
          initial: {
            opacity: 0,
            scale: .98
          },
          animate: {
            opacity: 1,
            scale: 1
          },
          transition: {
            duration: .24,
            ease: "easeOut"
          }
        }
      });
      function transform({ x = 0, y = 0, scale = 1 }) {
        const parts = [];
        if (x) parts.push(`translateX(${x}px)`);
        if (y) parts.push(`translateY(${y}px)`);
        if (scale !== 1) parts.push(`scale(${scale})`);
        return parts.length === 0 ? "none" : parts.join(" ");
      }
      function writeState(element, state) {
        if (state.opacity !== void 0) element.style.opacity = String(state.opacity);
        if (state.filter !== void 0) element.style.filter = state.filter;
        if (state.x !== void 0 || state.y !== void 0 || state.scale !== void 0) element.style.transform = transform(state);
        if (state.originX !== void 0 || state.originY !== void 0) {
          const x = (state.originX ?? .5) * 100;
          const y = (state.originY ?? .5) * 100;
          element.style.transformOrigin = `${x}% ${y}% 0px`;
        }
      }
      function keyframes(preset) {
        const frames = {};
        for (const property of [
          "opacity",
          "x",
          "y",
          "scale",
          "filter"
        ]) {
          if (preset.animate[property] === void 0) continue;
          frames[property] = [preset.initial[property] ?? preset.animate[property], preset.animate[property]];
        }
        return frames;
      }
      function reducedMotion() {
        return globalThis.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
      }
      function animateMessageEntry(element, presetId) {
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
      function stopMessageEntry(element) {
        running.get(element)?.stop();
        running.delete(element);
        element.removeAttribute(ACTIVE_ENTRY_ATTRIBUTE);
      }
      const SETTLE = 500;
      const SCROLL_POSITION_EPSILON = .5;
      const MESSAGE_SCROLL_KEYS = new Set([
        "ArrowDown",
        "ArrowUp",
        "End",
        "Home",
        "PageDown",
        "PageUp",
        " "
      ]);
      const MINIMUM_THUMB = 20;
      function finalComputedPixels(value) {
        const matches = [...String(value || "").matchAll(/(-?(?:\d+|\d*\.\d+))px\b/g)];
        const pixels = Number.parseFloat(matches.at(-1)?.[1]);
        return Number.isFinite(pixels) ? pixels : null;
      }
      function messageVirtualContentEnd(content, items) {
        if (!content || items.length === 0 || typeof getComputedStyle !== "function") return null;
        const contentStyle = getComputedStyle(content);
        const paddingTop = finalComputedPixels(contentStyle.paddingTop);
        const paddingBottom = finalComputedPixels(contentStyle.paddingBottom);
        const gap = finalComputedPixels(contentStyle.rowGap) ?? finalComputedPixels(contentStyle.gap);
        const intrinsicFact = items[0].getAttribute("data-lb-message-intrinsic-size");
        const itemSize = intrinsicFact && items.every((item) => item.getAttribute("data-lb-message-intrinsic-size") === intrinsicFact) ? finalComputedPixels(getComputedStyle(items[0]).containIntrinsicSize) : null;
        if (paddingTop === null || paddingBottom === null || gap === null || itemSize === null) return null;
        return paddingTop + paddingBottom + itemSize * items.length + gap * Math.max(0, items.length - 1);
      }
      function messageEndTarget(viewport) {
        return Math.max(0, viewport.scrollHeight - viewport.clientHeight);
      }
      const Scroller = {
        mounted() {
          this.viewport = this.el.querySelector("[data-lb-scroller]") || this.el;
          this.messageScroller = this.viewport.hasAttribute("data-lb-message-scroller-viewport");
          this.messageRoot = this.messageScroller ? this.viewport.closest("[data-lb-message-scroller]") : null;
          this.pendingTargets = [this.viewport, this.viewport.closest("[data-slot='message-scroller']")].filter((target) => target?.hasAttribute("data-pending-scroll"));
          this.onScroll = () => this.scrolled();
          this.viewport.addEventListener("scroll", this.onScroll, { passive: true });
          this.sticky = this.messageScroller ? this.messageRoot?.getAttribute("data-lb-message-auto-scroll") === "true" : this.el.hasAttribute("data-lb-stick-to-bottom");
          this.stuck = this.sticky;
          if (this.messageScroller) {
            this.installMessageScroller();
            this.animateMessageScrollerItems();
            if (this.applyInitialUnheldMessageOpeningPosition()) this.commitMessageScrollState();
          }
          this.observer = new ResizeObserver(() => this.resized());
          this.observer.observe(this.viewport);
          for (const child of this.viewport.children) this.observer.observe(child);
          for (const thumb of this.el.querySelectorAll("[data-lb-thumb]")) thumb.addEventListener("pointerdown", (event) => this.grab(event, thumb));
          this.measure();
          if (this.messageScroller) this.syncMessageState();
          if (this.sticky && !this.messageScroller) this.toBottom();
          if (this.messageScroller && !this.messageOpened || this.pendingTargets.length > 0) this.pendingFrame = requestAnimationFrame(() => {
            if (this.messageScroller && this.messageOpeningHold) this.settleMessageOpeningPosition();
            else if (this.messageScroller) this.applyMessageOpeningPosition();
            else if (this.sticky && this.stuck) this.toBottom();
            this.finishPendingScroll();
          });
        },
        beforeUpdate() {
          if (!this.messageScroller) return;
          this.releaseMessageFrozenOpeningPosition();
          const firstVisible = this.firstVisibleMessageItem();
          this.messageBeforeUpdate = {
            first: this.messageItems()[0]?.getAttribute("data-message-id") || null,
            firstVisible: firstVisible ? {
              id: firstVisible.getAttribute("data-message-id"),
              viewportTop: this.messageElementViewportTop(firstVisible)
            } : null,
            count: this.messageItems().length,
            height: this.viewport.scrollHeight,
            top: this.viewport.scrollTop,
            atEnd: this.atMessageEnd()
          };
        },
        updated() {
          if (this.messageScroller) {
            Scroller.refreshMessageScrollerElements.call(this);
            this.refreshMessageScrollerConfig();
            this.animateMessageScrollerItems();
            const updatedOpening = this.applyUpdatedMessageOpeningPosition();
            if (!(updatedOpening || (this.messageOpeningHold ? this.settleMessageOpeningPosition() : this.applyMessageOpeningPosition())) || !updatedOpening && this.messageBeforeUpdate) this.reconcileMessagePatch();
            this.measure();
            this.syncMessageState();
          } else {
            this.measure();
            if (this.sticky && this.stuck) this.toBottom();
          }
        },
        resized() {
          this.measure();
          if (this.messageScroller && this.messageOpeningFrozenTop !== null) this.restoreMessageFrozenOpeningPosition();
          else if (this.messageOpeningHold) {
            this.messageOpeningSawLayout = true;
            this.messageOpeningStableFrames = 0;
            this.settleMessageOpeningPosition();
          } else if (this.sticky && this.stuck) this.toBottom();
          else this.reanchorMessageItem();
          this.finishPendingScroll();
          if (this.messageScroller) this.syncMessageState();
        },
        installMessageScroller() {
          Scroller.refreshMessageScrollerElements.call(this);
          this.refreshMessageScrollerConfig();
          this.messageOpened = Boolean(this.viewport.__liveBaseMessageOpeningApplied);
          this.messageOpeningInitialTop = Number.isFinite(this.viewport.__liveBaseMessageOpeningTop) ? this.viewport.__liveBaseMessageOpeningTop : null;
          delete this.viewport.__liveBaseMessageOpeningApplied;
          delete this.viewport.__liveBaseMessageOpeningTop;
          this.messageOpeningHold = this.pendingTargets.length > 0 && this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false";
          this.messageOpeningSawLayout = false;
          this.messageOpeningStableFrames = 0;
          this.messageOpeningTarget = null;
          this.messageHandledAnchors = new WeakSet();
          this.messageAnimatedIds = new Set();
          this.messageVisibleIds = new Set();
          this.messageSpacerHeight = null;
          this.messageAnchoredItem = null;
          this.messageOpeningUsesIntrinsicLayout = false;
          this.messageDefaultPosition = this.messageRoot?.getAttribute("data-lb-message-default-position") || "end";
          this.messageOpeningGeneration = this.messageRoot?.getAttribute("data-lb-message-opening-generation") || null;
          if (this.messageOpened && this.messageOpeningInitialTop !== null && this.messageRoot?.getAttribute("data-lb-message-opening-hold") === "false") {
            this.messageOpeningFrozenTop = this.messageOpeningInitialTop;
            this.viewport.scrollTop = this.messageOpeningInitialTop;
            this.restoreMessageFrozenOpeningPosition();
          } else this.messageOpeningFrozenTop = null;
          this.onMessageClick = (event) => {
            const button = event.target.closest("[data-slot='message-scroller-button']");
            if (!button || !this.messageRoot?.contains(button) || button.hasAttribute("inert")) return;
            const direction = button.getAttribute("data-direction") || "end";
            const behavior = button.getAttribute("data-lb-message-scroll-behavior") || "smooth";
            if (direction === "start") this.scrollMessageToStart({ behavior });
            else this.scrollMessageToEnd({ behavior });
          };
          this.onMessageScrollTo = (event) => {
            const request = event.detail || {};
            if (this.scrollMessageToRequest(request) || !request.id) return;
            const { id, align = "start", behavior = "auto", scrollMargin } = request;
            const options = {
              align,
              behavior,
              scrollMargin
            };
            if (this.messageItems().length === 0) this.pendingMessageScroll = {
              id,
              options
            };
          };
          this.messageRoot?.addEventListener("click", this.onMessageClick);
          this.messageRoot?.addEventListener("message-scroller:scroll-to", this.onMessageScrollTo);
          this.onMessageUserScrollIntent = (event) => {
            if (event.type !== "keydown" || MESSAGE_SCROLL_KEYS.has(event.key)) {
              this.releaseMessageFrozenOpeningPosition();
              if (event.type !== "pointerdown") this.messageAnchoredItem = null;
            }
          };
          for (const type of [
            "keydown",
            "pointerdown",
            "touchmove",
            "wheel"
          ]) this.viewport.addEventListener(type, this.onMessageUserScrollIntent, { passive: true });
          this.messageVisibilityEnabled = this.hasMessageVisibilityConsumer();
          this.messageVisibilityReady = !this.messageVisibilityEnabled || this.pendingTargets.length === 0;
          if (this.messageVisibilityReady) this.installMessageVisibilityObserver();
        },
        activateMessageVisibility() {
          if (!this.messageVisibilityEnabled || this.messageVisibilityReady) return false;
          this.messageVisibilityReady = true;
          this.installMessageVisibilityObserver();
          this.syncMessageState();
          return true;
        },
        hasMessageVisibilityConsumer() {
          const controller = this.messageRoot?.id;
          if (!controller || typeof document === "undefined") return false;
          return Array.from(document.querySelectorAll("[data-message-scroller-outline]")).some((outline) => outline.getAttribute("data-message-scroller-controller") === controller);
        },
        installMessageVisibilityObserver() {
          if (!this.messageVisibilityEnabled || typeof IntersectionObserver === "undefined" || !this.viewport) return;
          this.messageVisibilityObserver = new IntersectionObserver((entries) => {
            for (const entry of entries) {
              const id = entry.target.getAttribute("data-message-id");
              if (!id) continue;
              if (entry.isIntersecting) this.messageVisibleIds.add(id);
              else this.messageVisibleIds.delete(id);
            }
            this.syncMessageState();
          }, {
            root: this.viewport,
            rootMargin: `${-(this.messageMargin + this.messagePreviousPeek)}px 0px 0px 0px`,
            threshold: [
              0,
              .01,
              .5,
              1
            ]
          });
          this.observeMessageVisibilityItems();
        },
        observeMessageVisibilityItems() {
          if (!this.messageVisibilityObserver) return;
          for (const item of this.messageItems()) this.messageVisibilityObserver.observe(item);
        },
        refreshMessageScrollerElements() {
          const content = this.viewport?.querySelector?.("[data-slot='message-scroller-content']");
          if (!content) return;
          const spacer = content?.querySelector("[data-message-scroller-spacer]");
          if (content === this.messageContent && spacer === this.messageSpacer) return;
          this.messageContent = content;
          this.messageSpacer = spacer;
          this.messageSpacerHeight = spacer?.hidden ? 0 : null;
        },
        refreshMessageScrollerConfig() {
          this.messageMargin = Number(this.messageRoot?.getAttribute("data-lb-message-scroll-margin")) || 0;
          this.messagePreviousPeek = Number(this.messageRoot?.getAttribute("data-lb-message-previous-peek")) || 0;
          this.messageThreshold = Number(this.messageRoot?.getAttribute("data-lb-message-scroll-edge-threshold")) || 8;
        },
        applyUpdatedMessageOpeningPosition() {
          const position = this.messageRoot?.getAttribute("data-lb-message-default-position") || "end";
          const generation = this.messageRoot?.getAttribute("data-lb-message-opening-generation") || null;
          const positionChanged = position !== this.messageDefaultPosition;
          const generationChanged = generation !== this.messageOpeningGeneration;
          if (!positionChanged && !generationChanged) return false;
          this.messageDefaultPosition = position;
          this.messageOpeningGeneration = generation;
          this.clearMessageOpeningMaterialization?.();
          if (generationChanged) return this.restartMessageOpeningPosition({ intrinsicLayout: true });
          if (positionChanged && position === "last-anchor") return this.restartMessageOpeningPosition();
          this.messageOpened = false;
          return this.applyMessageOpeningPosition();
        },
        restartMessageOpeningPosition({ intrinsicLayout = false } = {}) {
          this.messageOpened = false;
          this.messageOpeningFrozenTop = null;
          this.messageOpeningUsesIntrinsicLayout = intrinsicLayout;
          this.clearMessageOpeningMaterialization?.();
          this.pendingTargets = [this.viewport, this.messageRoot].filter(Boolean);
          this.messageOpeningHold = this.pendingTargets.length > 0 && this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false";
          this.messageOpeningSawLayout = false;
          this.messageOpeningStableFrames = 0;
          this.messageOpeningTarget = null;
          for (const target of this.pendingTargets) target.setAttribute("data-pending-scroll", "");
          if (this.messageOpeningHold) this.settleMessageOpeningPosition();
          else {
            this.applyMessageOpeningPosition();
            this.finishPendingScroll();
          }
          return true;
        },
        restoreMessageFrozenOpeningPosition() {
          if (this.messageOpeningFrozenTop === null) return false;
          const target = this.messageOpeningFrozenTop;
          if (Math.abs(this.viewport.scrollTop - target) > SCROLL_POSITION_EPSILON) this.viewport.scrollTop = target;
          this.stuck = this.atMessageEnd();
          this.syncMessageState();
          return true;
        },
        releaseMessageFrozenOpeningPosition() {
          this.messageOpeningFrozenTop = null;
        },
        materializeMessageOpeningAnchor(items, anchor) {
          if (this.messageOpeningMaterializedItems || !anchor) return;
          const materialized = [];
          for (const item of items) {
            materialized.push({
              item,
              contentVisibility: item.style.contentVisibility
            });
            item.style.contentVisibility = "visible";
            if (item === anchor) break;
          }
          this.messageOpeningMaterializedItems = materialized;
        },
        clearMessageOpeningMaterialization() {
          for (const { item, contentVisibility } of this.messageOpeningMaterializedItems || []) item.style.contentVisibility = contentVisibility;
          this.messageOpeningMaterializedItems = null;
        },
        applyInitialUnheldMessageOpeningPosition() {
          if (this.messageOpened || this.messageOpeningHold || this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false") return false;
          this.messageOpened = true;
          this.clearMessageSpacer();
          this.messageAnchoredItem = null;
          this.markMessageAutoscrolling();
          this.commitMessageScrollState();
          this.viewport.scrollTo({
            top: messageEndTarget(this.viewport),
            behavior: "auto"
          });
          this.stuck = true;
          this.scheduleMessageScrollStateCommit();
          return true;
        },
        commitMessageScrollState() {
          this.syncMessageState(this.messageMeasuredContentBottom());
        },
        scheduleMessageScrollStateCommit() {
          if (this.messageStateFrame) return;
          this.messageStateFrame = requestAnimationFrame(() => {
            this.messageStateFrame = null;
            this.commitMessageScrollState();
          });
        },
        messageMeasuredContentBottom() {
          const { start, end } = this.messageContentPadding();
          const viewportBounds = this.viewport.getBoundingClientRect();
          let bottom = start + end;
          for (const item of this.messageItems()) {
            const bounds = item.getBoundingClientRect();
            bottom = Math.max(bottom, bounds.bottom - viewportBounds.top + this.viewport.scrollTop + end);
          }
          return bottom;
        },
        settleMessageOpeningPosition() {
          if (!this.messageOpeningHold) return false;
          const before = this.viewport.scrollTop;
          this.messageOpened = false;
          if (!this.applyMessageOpeningPosition()) return false;
          this.messageOpeningSawLayout = true;
          const target = this.viewport.scrollTop;
          const stable = this.messageOpeningSawLayout && this.messageOpeningTarget === target && before === target;
          this.messageOpeningTarget = target;
          this.messageOpeningStableFrames = stable ? this.messageOpeningStableFrames + 1 : 0;
          if (this.messageOpeningStableFrames >= 2) {
            this.messageOpeningHold = false;
            this.finishPendingScroll();
            return true;
          }
          cancelAnimationFrame(this.messageOpeningFrame);
          this.messageOpeningFrame = requestAnimationFrame(() => {
            this.messageOpeningFrame = null;
            this.settleMessageOpeningPosition();
          });
          return true;
        },
        messageItems() {
          if (!this.messageContent) this.messageContent = this.viewport.querySelector("[data-slot='message-scroller-content']");
          return [...this.messageContent?.children || []].filter((item) => item instanceof HTMLElement && !item.hasAttribute("data-message-scroller-spacer"));
        },
        messageContentPadding() {
          const style = this.messageContent ? getComputedStyle(this.messageContent) : null;
          return {
            start: Number.parseFloat(style?.paddingBlockStart || style?.paddingTop) || 0,
            end: Number.parseFloat(style?.paddingBlockEnd || style?.paddingBottom) || 0
          };
        },
        messageElementTop(item) {
          return item.getBoundingClientRect().top - this.viewport.getBoundingClientRect().top + this.viewport.scrollTop;
        },
        messageElementHeight(item) {
          return item.getBoundingClientRect().height;
        },
        messageContentBottom() {
          const { start, end } = this.messageContentPadding();
          let bottom = start + end;
          for (const item of this.messageItems()) bottom = Math.max(bottom, this.messageElementTop(item) + this.messageElementHeight(item) + end);
          return bottom;
        },
        messageVirtualContentEnd() {
          return messageVirtualContentEnd(this.messageContent, this.messageItems());
        },
        messageSpacerContentEnd() {
          if (this.messageOpeningUsesIntrinsicLayout) {
            const intrinsicEnd = this.messageVirtualContentEnd();
            if (intrinsicEnd !== null) return intrinsicEnd;
          }
          return this.messageContentBottom();
        },
        messageElementViewportTop(item) {
          return item.getBoundingClientRect().top - this.viewport.getBoundingClientRect().top;
        },
        firstVisibleMessageItem() {
          const viewportBounds = this.viewport.getBoundingClientRect();
          return this.messageItems().find((item) => {
            const bounds = item.getBoundingClientRect();
            return bounds.bottom > viewportBounds.top && bounds.top < viewportBounds.bottom;
          });
        },
        atMessageStart() {
          return this.viewport.scrollTop <= this.messageThreshold;
        },
        atMessageEnd() {
          const height = this.viewport.scrollHeight;
          const top = this.viewport.scrollTop;
          const clientHeight = this.viewport.clientHeight;
          this.messageNativeScrollRange = {
            top,
            maximum: Math.max(0, height - clientHeight)
          };
          return height - top - clientHeight <= this.messageThreshold;
        },
        applyMessageOpeningPosition() {
          const items = this.messageItems();
          if (this.messageOpened || items.length === 0) return false;
          this.messageOpened = true;
          const position = this.messageRoot?.getAttribute("data-lb-message-default-position") || "end";
          if (position === "start") this.scrollMessageToStart();
          else if (position === "last-anchor") {
            const anchor = items.filter((item) => item.dataset.scrollAnchor === "true").at(-1);
            if (this.messageOpeningHold) this.materializeMessageOpeningAnchor(items, anchor);
            if (!anchor || this.messageContentBottom() - this.messageElementTop(anchor) <= this.viewport.clientHeight) this.scrollMessageToEnd({ useIntrinsicLayout: this.messageOpeningUsesIntrinsicLayout });
            else this.scrollMessageToElement(anchor, {
              align: "start",
              keepPreviousPeek: true
            });
          } else this.scrollMessageToEnd({ useIntrinsicLayout: this.messageOpeningUsesIntrinsicLayout });
          this.stuck = this.atMessageEnd();
          this.syncMessageState();
          return true;
        },
        reconcileMessagePatch() {
          Scroller.refreshMessageScrollerElements.call(this);
          const before = this.messageBeforeUpdate;
          this.messageBeforeUpdate = null;
          if (!before) return;
          const preserves = this.viewport.getAttribute("data-lb-message-preserve-prepend") !== "false";
          const first = this.messageContent?.firstElementChild?.getAttribute("data-message-id") || null;
          if (preserves && before.first && first && first !== before.first) {
            const anchor = before.firstVisible?.id ? this.messageContent?.querySelector(`[data-message-id=${JSON.stringify(before.firstVisible.id)}]`) : null;
            if (anchor) {
              const delta = this.messageElementViewportTop(anchor) - before.firstVisible.viewportTop;
              if (Math.abs(delta) > SCROLL_POSITION_EPSILON) this.viewport.scrollTop += delta;
            }
            this.syncMessageState();
            return;
          }
          const items = this.messageItems();
          if (this.pendingMessageScroll) {
            const { id, options } = this.pendingMessageScroll;
            if (this.scrollMessageToId(id, options)) {
              this.pendingMessageScroll = null;
              return;
            }
          }
          const addedAnchors = (items.length > before.count ? items.slice(before.count) : []).filter((item) => item.dataset.scrollAnchor === "true" && !this.messageHandledAnchors.has(item));
          if (addedAnchors.length > 0) {
            if (this.sticky) {
              if (before.atEnd) this.scrollMessageToEnd();
            } else this.scrollMessageToElement(addedAnchors[0], {
              align: "start",
              keepPreviousPeek: true
            });
            for (const anchor of addedAnchors) this.messageHandledAnchors.add(anchor);
          } else if (this.sticky && before.atEnd) this.scrollMessageToEnd();
        },
        animateMessageScrollerItems() {
          for (const item of this.messageItems()) {
            const preset = item.getAttribute("data-lb-message-animation");
            const id = item.getAttribute("data-message-id");
            if (!preset || !id || this.messageAnimatedIds.has(id)) continue;
            this.messageAnimatedIds.add(id);
            this.reanchorMessageEntryAfterFinish(item, animateMessageEntry(item, preset));
          }
        },
        reanchorMessageEntryAfterFinish(item, controls) {
          controls?.finished?.then(() => {
            if (this.messageAnchoredItem !== item || !item.isConnected) return;
            const outcome = this.messageEntryAnchorOutcome;
            if (outcome?.item === item && outcome.requestedTop > outcome.maximum && outcome.top === outcome.maximum && outcome.margin === this.messageMargin + this.messagePreviousPeek && outcome.generation === this.messageRoot?.getAttribute("data-lb-message-opening-generation")) {
              const sameSpacer = () => outcome.spacer === this.messageSpacer && outcome.spacerHeight === this.messageSpacerHeight && outcome.spacerHidden === this.messageSpacer?.hidden && outcome.spacerStyleHeight === this.messageSpacer?.style?.height && outcome.spacerMarginTop === this.messageSpacer?.style?.marginTop;
              if (sameSpacer()) {
                this.atMessageEnd();
                const current = this.messageNativeScrollRange;
                if (sameSpacer() && current.top === outcome.top && current.maximum === outcome.maximum) return;
              }
            }
            this.reanchorMessageItem();
          }, () => {});
        },
        scrollMessageToStart({ behavior = "auto" } = {}) {
          this.clearMessageSpacer();
          this.messageAnchoredItem = null;
          this.viewport.scrollTo({
            top: 0,
            behavior
          });
          this.stuck = false;
          this.syncMessageState();
          return true;
        },
        scrollMessageToEnd({ behavior = "auto", sync = true, useIntrinsicLayout = false } = {}) {
          this.clearMessageSpacer();
          this.messageAnchoredItem = null;
          this.markMessageAutoscrolling();
          const intrinsicEnd = useIntrinsicLayout ? Scroller.messageVirtualContentEnd.call(this) : null;
          const top = intrinsicEnd === null ? messageEndTarget(this.viewport) : Math.max(0, intrinsicEnd - this.viewport.clientHeight);
          this.viewport.scrollTo({
            top,
            behavior
          });
          this.stuck = true;
          if (sync) this.syncMessageState();
          return true;
        },
        scrollMessageToRequest({ id, direction, align = "start", behavior = "auto", scrollMargin } = {}) {
          if (direction === "start") {
            this.releaseMessageFrozenOpeningPosition();
            return this.scrollMessageToStart({ behavior });
          }
          if (direction === "end") {
            this.releaseMessageFrozenOpeningPosition();
            return this.scrollMessageToEnd({ behavior });
          }
          if (!id) return false;
          this.releaseMessageFrozenOpeningPosition();
          return this.scrollMessageToId(id, {
            align,
            behavior,
            scrollMargin
          });
        },
        markMessageAutoscrolling() {
          this.autoscrolling = true;
          clearTimeout(this.autoscrollingTimer);
          this.autoscrollingTimer = setTimeout(() => {
            this.autoscrolling = false;
            this.syncMessageState();
          }, 180);
        },
        scrollMessageToId(id, options = {}) {
          const item = this.messageItems().find((candidate) => candidate.getAttribute("data-message-id") === id);
          return item ? this.scrollMessageToElement(item, options) : false;
        },
        scrollMessageToElement(item, { align = "start", behavior = "auto", scrollMargin, keepPreviousPeek = false } = {}) {
          const margin = (scrollMargin ?? this.messageMargin) + (keepPreviousPeek ? this.messagePreviousPeek : 0);
          const { start: paddingStart, end: paddingEnd } = this.messageContentPadding();
          const offset = this.messageElementTop(item);
          const height = this.messageElementHeight(item);
          let top = offset - paddingStart - margin;
          if (align === "center") {
            const insetHeight = Math.max(0, this.viewport.clientHeight - paddingStart - paddingEnd);
            top = offset - paddingStart - (insetHeight - height) / 2 - margin;
          }
          if (align === "end") top = offset - this.viewport.clientHeight + height + paddingEnd + margin;
          if (align === "nearest") {
            const elementBottom = offset + height;
            const visibleStart = this.viewport.scrollTop + paddingStart;
            const visibleEnd = this.viewport.scrollTop + this.viewport.clientHeight - paddingEnd;
            if (offset >= visibleStart && elementBottom <= visibleEnd) top = this.viewport.scrollTop;
            else if (offset < visibleStart) top = offset - paddingStart - margin;
            else top = elementBottom - this.viewport.clientHeight + paddingEnd + margin;
          }
          this.updateMessageSpacer(top);
          this.messageAnchoredItem = keepPreviousPeek ? item : null;
          this.viewport.scrollTo({
            top: Math.max(0, top),
            behavior
          });
          this.stuck = this.atMessageEnd();
          const range = this.messageNativeScrollRange;
          this.messageEntryAnchorOutcome = keepPreviousPeek && range ? {
            item,
            requestedTop: Math.max(0, top),
            top: range.top,
            maximum: range.maximum,
            margin,
            generation: this.messageRoot?.getAttribute("data-lb-message-opening-generation"),
            spacer: this.messageSpacer,
            spacerHeight: this.messageSpacerHeight,
            spacerHidden: this.messageSpacer?.hidden,
            spacerStyleHeight: this.messageSpacer?.style?.height,
            spacerMarginTop: this.messageSpacer?.style?.marginTop
          } : null;
          this.syncMessageState();
          return true;
        },
        syncMessageState(contentBottom = null) {
          if (!this.messageScroller) return;
          const atStart = this.atMessageStart();
          const atEnd = contentBottom === null ? this.atMessageEnd() : contentBottom - this.viewport.scrollTop - this.viewport.clientHeight <= this.messageThreshold;
          const start = !atStart;
          const end = !atEnd;
          const state = [start && "start", end && "end"].filter(Boolean).join(" ");
          for (const target of [this.messageRoot, this.viewport]) {
            if (!target) continue;
            if (state) target.setAttribute("data-scrollable", state);
            else target.removeAttribute("data-scrollable");
            target.toggleAttribute("data-autoscrolling", Boolean(this.autoscrolling));
          }
          this.syncMessageScrollStateBindings(state);
          for (const button of this.messageRoot?.querySelectorAll("[data-slot='message-scroller-button']") || []) {
            const active = button.getAttribute("data-direction") === "start" ? start : end;
            button.setAttribute("data-active", String(active));
            button.toggleAttribute("inert", !active);
            button.tabIndex = active ? 0 : -1;
          }
          const tracksVisibility = this.messageVisibilityEnabled && this.messageVisibilityReady;
          const tracksVisibilityByLayout = tracksVisibility && !this.messageVisibilityObserver;
          const visibleMessageIds = [];
          let currentAnchorId = null;
          if (tracksVisibility) {
            this.observeMessageVisibilityItems();
            const viewportBounds = this.viewport.getBoundingClientRect();
            const edge = viewportBounds.top + this.messageMargin + this.messagePreviousPeek;
            for (const item of this.messageItems()) {
              const messageId = item.getAttribute("data-message-id");
              const isAnchor = item.dataset.scrollAnchor === "true";
              const bounds = isAnchor || tracksVisibilityByLayout ? item.getBoundingClientRect() : null;
              const visible = tracksVisibilityByLayout && bounds ? bounds.bottom > edge && bounds.top < viewportBounds.bottom : Boolean(messageId && this.messageVisibleIds.has(messageId));
              if (messageId && visible) visibleMessageIds.push(messageId);
              if (isAnchor && bounds && bounds.top <= edge + .5) currentAnchorId = messageId;
            }
          }
          if (currentAnchorId) this.viewport.setAttribute("data-current-anchor-id", currentAnchorId);
          else this.viewport.removeAttribute("data-current-anchor-id");
          if (tracksVisibility) this.syncMessageOutline(currentAnchorId);
          const detail = {
            start,
            end,
            currentAnchorId,
            visibleMessageIds
          };
          this.viewport.dispatchEvent(new CustomEvent("message-scroller:state", {
            bubbles: true,
            detail
          }));
        },
        syncMessageOutline(currentAnchorId) {
          const controller = this.messageRoot?.id;
          if (!controller) return;
          for (const outline of document.querySelectorAll("[data-message-scroller-outline]")) {
            if (outline.getAttribute("data-message-scroller-controller") !== controller) continue;
            for (const bar of outline.querySelectorAll("[data-message-scroller-outline-bar]")) {
              const active = bar.getAttribute("data-message-scroller-anchor-id") === currentAnchorId;
              bar.setAttribute("data-current", String(active));
            }
            for (const choice of outline.querySelectorAll("[data-message-scroller-outline-choice]")) if (choice.getAttribute("data-message-scroller-anchor-id") === currentAnchorId) choice.setAttribute("aria-current", "location");
            else choice.removeAttribute("aria-current");
          }
        },
        syncMessageScrollStateBindings(state) {
          const controller = this.messageRoot?.id;
          if (!controller) return;
          const status = state || "none";
          for (const target of document.querySelectorAll("[data-lb-message-scroll-state-for]")) {
            if (target.getAttribute("data-lb-message-scroll-state-for") !== controller) continue;
            if (state) target.setAttribute("data-scrollable", state);
            else target.removeAttribute("data-scrollable");
            for (const messageStatus of target.querySelectorAll("[data-lb-message-scroll-status]")) messageStatus.hidden = messageStatus.getAttribute("data-lb-message-scroll-status") !== status;
          }
        },
        updateMessageSpacer(scrollTop) {
          const spacer = this.messageSpacer;
          if (!spacer || !this.messageContent) return;
          const height = Math.max(0, Math.ceil(Math.max(0, scrollTop) + this.viewport.clientHeight - this.messageSpacerContentEnd()));
          if (this.messageSpacerHeight === height) return;
          this.messageSpacerHeight = height;
          spacer.hidden = height === 0;
          spacer.style.height = `${height}px`;
          if (height > 0) {
            const contentStyle = getComputedStyle(this.messageContent);
            const gap = contentStyle.rowGap === "normal" ? contentStyle.gap : contentStyle.rowGap;
            spacer.style.marginTop = `${-(Number.parseFloat(gap) || 0)}px`;
          } else spacer.style.marginTop = "";
        },
        clearMessageSpacer() {
          const spacer = this.messageSpacer;
          if (!spacer) return;
          if (this.messageSpacerHeight === 0) return;
          this.messageSpacerHeight = 0;
          spacer.hidden = true;
          spacer.style.height = "0px";
          spacer.style.marginTop = "";
        },
        reanchorMessageItem() {
          const item = this.messageAnchoredItem;
          if (!item || !item.isConnected || !this.messageContent?.contains(item)) return false;
          return this.scrollMessageToElement(item, {
            align: "start",
            keepPreviousPeek: true
          });
        },
        toBottom() {
          const offset = Number(this.el.getAttribute("data-lb-bottom-offset")) || 0;
          this.viewport.scrollTop = Math.max(0, this.viewport.scrollHeight - this.viewport.clientHeight - offset);
        },
        destroyed() {
          this.viewport.removeEventListener("scroll", this.onScroll);
          this.observer?.disconnect();
          cancelAnimationFrame(this.pendingFrame);
          cancelAnimationFrame(this.messageOpeningFrame);
          cancelAnimationFrame(this.messageStateFrame);
          clearTimeout(this.timer);
          clearTimeout(this.autoscrollingTimer);
          this.messageRoot?.removeEventListener("click", this.onMessageClick);
          this.messageRoot?.removeEventListener("message-scroller:scroll-to", this.onMessageScrollTo);
          for (const type of [
            "keydown",
            "pointerdown",
            "touchmove",
            "wheel"
          ]) this.viewport.removeEventListener(type, this.onMessageUserScrollIntent);
          this.messageVisibilityObserver?.disconnect();
          this.clearMessageOpeningMaterialization?.();
          for (const item of this.messageItems()) stopMessageEntry(item);
        },
        finishPendingScroll() {
          if (this.messageOpeningFrame) return;
          if (this.messageOpeningHold) return;
          if (this.messageScroller && !this.messageOpened && this.messageItems().length > 0) return;
          for (const target of this.pendingTargets) target.removeAttribute("data-pending-scroll");
          this.clearMessageOpeningMaterialization?.();
          this.messageOpeningUsesIntrinsicLayout = false;
          cancelAnimationFrame(this.pendingFrame);
          this.pendingFrame = null;
          this.activateMessageVisibility?.();
        },
        measure() {
          const { scrollHeight, clientHeight, scrollWidth, clientWidth } = this.viewport;
          this.axis("y", scrollHeight, clientHeight, this.viewport.scrollTop);
          this.axis("x", scrollWidth, clientWidth, this.viewport.scrollLeft);
        },
        axis(name, total, visible, offset) {
          const overflowing = total > visible + 1;
          const orientation = axis(name);
          for (const scrollbar of this.el.querySelectorAll(`[data-slot='scroll-area-scrollbar'][data-orientation='${orientation}']`)) scrollbar.toggleAttribute("hidden", !overflowing);
          const targets = [this.el, ...this.el.querySelectorAll("[data-slot]")];
          for (const target of targets) {
            target.toggleAttribute(`data-has-overflow-${name}`, overflowing);
            target.toggleAttribute(`data-overflow-${name}-start`, overflowing && offset > 0);
            target.toggleAttribute(`data-overflow-${name}-end`, overflowing && offset + visible < total - 1);
          }
          const track = this.track(name);
          const size = overflowing ? Math.max(MINIMUM_THUMB, visible / total * track) : 0;
          const travel = Math.max(0, total - visible);
          const at = travel === 0 ? 0 : offset / travel * (track - size);
          const style = this.el.style;
          style.setProperty(`--scroll-area-thumb-${name === "y" ? "height" : "width"}`, `${size}px`);
          style.setProperty(`--scroll-area-overflow-${name}-start`, travel === 0 ? "0" : offset / travel);
          style.setProperty(`--scroll-area-overflow-${name}-end`, travel === 0 ? "0" : 1 - offset / travel);
          for (const thumb of this.el.querySelectorAll(`[data-lb-thumb][data-orientation='${orientation}']`)) {
            if (name === "y") thumb.style.height = `${size}px`;
            else thumb.style.width = `${size}px`;
            thumb.style.transform = name === "y" ? `translate3d(0, ${at}px, 0)` : `translate3d(${at}px, 0, 0)`;
          }
        },
        scrolled() {
          if (this.messageScroller && this.messageOpeningFrozenTop !== null) {
            this.restoreMessageFrozenOpeningPosition();
            return;
          }
          if (this.sticky) {
            const { scrollTop, scrollHeight, clientHeight } = this.viewport;
            this.stuck = scrollHeight - scrollTop - clientHeight <= 1;
          }
          this.mark();
          this.measure();
          if (this.messageScroller) this.syncMessageState();
        },
        mark() {
          clearTimeout(this.timer);
          for (const target of this.scrollables()) target.toggleAttribute("data-scrolling", true);
          this.timer = setTimeout(() => {
            for (const target of this.scrollables()) target.removeAttribute("data-scrolling");
          }, SETTLE);
        },
        scrollables() {
          return [this.el, ...this.el.querySelectorAll("[data-slot]")];
        },
        track(name) {
          const style = getComputedStyle(this.el);
          const start = parseFloat(name === "y" ? style.paddingTop : style.paddingLeft) || 0;
          const end = parseFloat(name === "y" ? style.paddingBottom : style.paddingRight) || 0;
          const size = name === "y" ? this.el.clientHeight : this.el.clientWidth;
          return Math.max(0, size - start - end - 2);
        },
        grab(event, thumb) {
          event.preventDefault();
          thumb.setPointerCapture(event.pointerId);
          const vertical = thumb.getAttribute("data-orientation") !== "horizontal";
          const start = vertical ? event.clientY : event.clientX;
          const from = vertical ? this.viewport.scrollTop : this.viewport.scrollLeft;
          const total = vertical ? this.viewport.scrollHeight : this.viewport.scrollWidth;
          const visible = vertical ? this.viewport.clientHeight : this.viewport.clientWidth;
          const track = this.track(vertical ? "y" : "x");
          const size = Math.max(MINIMUM_THUMB, visible / total * track);
          const move = (moved) => {
            const travelled = (vertical ? moved.clientY : moved.clientX) - start;
            const room = track - size;
            const scrolled = room === 0 ? 0 : travelled / room * (total - visible);
            if (vertical) this.viewport.scrollTop = from + scrolled;
            else this.viewport.scrollLeft = from + scrolled;
          };
          const release = () => {
            thumb.removeEventListener("pointermove", move);
            thumb.removeEventListener("pointerup", release);
            thumb.removeEventListener("pointercancel", release);
          };
          thumb.addEventListener("pointermove", move);
          thumb.addEventListener("pointerup", release);
          thumb.addEventListener("pointercancel", release);
        }
      };
      function axis(name) {
        return name === "y" ? "vertical" : "horizontal";
      }
      export default Scroller;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc """
  The attributes the client owns once the page is live.

  Every one of them is a measurement, so a patch that re-rendered the scroll
  area would put back what the server guessed on the first paint: nothing
  overflowing and a thumb of no height.
  """
  def owned_attributes(js \\ %JS{}) do
    JS.ignore_attributes(
      js,
      ~w(data-has-overflow-x data-has-overflow-y data-overflow-x-start data-overflow-x-end
         data-overflow-y-start data-overflow-y-end data-scrolling style),
      []
    )
  end

  @doc "Keeps a server patch from restoring the completed opening-scroll hold."
  def pending_attributes(js \\ %JS{}) do
    JS.ignore_attributes(js, ["data-pending-scroll"], [])
  end

  @doc "Keeps Message Scroller client state through a LiveView patch."
  def message_attributes(js \\ %JS{}, part)

  def message_attributes(js, part) when part in [:root, :viewport] do
    JS.ignore_attributes(
      js,
      ["data-scrollable", "data-autoscrolling", "data-current-anchor-id"],
      []
    )
  end

  def message_attributes(js, :button) do
    JS.ignore_attributes(js, ["data-active", "inert", "tabindex"], [])
  end

  @doc "Scrolls a Message Scroller item into view through its controller root."
  def scroll_to_message(controller_id, message_id, opts \\ []) when is_list(opts) do
    scroll_to_message(%JS{}, controller_id, message_id, opts)
  end

  def scroll_to_message(%JS{} = js, controller_id, message_id, opts) when is_list(opts) do
    JS.dispatch(js, "message-scroller:scroll-to",
      to: "##{controller_id}",
      detail: %{
        id: message_id,
        align: Keyword.get(opts, :align, "start"),
        behavior: Keyword.get(opts, :behavior, "auto"),
        scrollMargin: Keyword.get(opts, :scroll_margin)
      }
    )
  end
end
