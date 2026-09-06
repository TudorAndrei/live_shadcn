// The scroll-area hook.
//
// Base UI's scroll area replaces the platform scrollbar with one the style
// sheet can reach. Everything that takes — how much there is to scroll, how far
// down the reader is, how tall the thumb should be — is a measurement, and a
// measurement is the one thing a `Phoenix.LiveView.JS` command cannot make.
//
// So the hook measures and writes, and decides nothing else. Every rule that
// reads what it writes is shadcn's, unchanged:
//
//   data-has-overflow-x     there is more content than fits, across
//   data-has-overflow-y     the same, down
//   data-overflow-x-start   there is content hidden off the start edge
//   data-overflow-x-end     …off the end edge
//   data-overflow-y-start   the same, up
//   data-overflow-y-end     the same, down
//   data-scrolling          present while the reader is scrolling, briefly after
//
//   --scroll-area-thumb-height   how tall the thumb is, in pixels
//   --scroll-area-thumb-width    how wide
//   --scroll-area-overflow-y-start  how far down the reader has scrolled, 0 to 1
//   --scroll-area-overflow-y-end    how far is left
//   --scroll-area-overflow-x-start  the same, across
//   --scroll-area-overflow-x-end
//
// Declared on the root:
//
//   data-lb-scroller   on the viewport, the element that actually scrolls
//   data-lb-thumb      on each thumb, so dragging one scrolls the viewport
//
// The thumb's *position* is a style, not a variable: `translate3d` on the thumb
// itself. Base UI does the same, because a transform is the one property a
// browser moves without laying the page out again.

// How long `data-scrolling` outlives the last scroll event. Long enough that a
// scrollbar which fades in does not flicker between two flicks of a wheel.
import { animateMessageEntry, stopMessageEntry } from "./message_animation.js";

const SETTLE = 500;
const SCROLL_POSITION_EPSILON = 0.5;
const MESSAGE_SCROLL_KEYS = new Set([
  "ArrowDown",
  "ArrowUp",
  "End",
  "Home",
  "PageDown",
  "PageUp",
  " ",
]);

// A thumb smaller than this is one nobody can grab.
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
  const uniform = intrinsicFact && items.every(
    (item) => item.getAttribute("data-lb-message-intrinsic-size") === intrinsicFact,
  );
  const itemSize = uniform
    ? finalComputedPixels(getComputedStyle(items[0]).containIntrinsicSize)
    : null;

  if (paddingTop === null || paddingBottom === null || gap === null || itemSize === null) {
    return null;
  }

  const size = paddingTop + paddingBottom + itemSize * items.length +
    gap * Math.max(0, items.length - 1);

  return size;
}

function messageEndTarget(viewport) {
  return Math.max(0, viewport.scrollHeight - viewport.clientHeight);
}

export const Scroller = {
  mounted() {
    this.viewport = this.el.querySelector("[data-lb-scroller]") || this.el;
    this.messageScroller = this.viewport.hasAttribute("data-lb-message-scroller-viewport");
    this.messageRoot = this.messageScroller
      ? this.viewport.closest("[data-lb-message-scroller]")
      : null;
    this.pendingTargets = [
      this.viewport,
      this.viewport.closest("[data-slot='message-scroller']"),
    ].filter((target) => target?.hasAttribute("data-pending-scroll"));

    this.onScroll = () => this.scrolled();
    this.viewport.addEventListener("scroll", this.onScroll, { passive: true });

    // A message list opens at the newest message, not the oldest. Upstream
    // reaches that with `use-stick-to-bottom`; here it is one attribute and two
    // rules — start at the bottom, and stay there while the reader is already
    // there.
    this.sticky = this.messageScroller
      ? this.messageRoot?.getAttribute("data-lb-message-auto-scroll") === "true"
      : this.el.hasAttribute("data-lb-stick-to-bottom");
    this.stuck = this.sticky;

    if (this.messageScroller) {
      this.installMessageScroller();
      this.animateMessageScrollerItems();
      const opened = this.applyInitialUnheldMessageOpeningPosition();
      if (opened) this.commitMessageScrollState();
    }

    // React applies its default opening and captures the prepend anchor in
    // layout effects. Its ResizeObservers start later in normal effects.
    // Registering ours only after that sequence preserves the same lazy-row
    // realization and browser scroll-anchoring result.
    this.observer = new ResizeObserver(() => this.resized());
    this.observer.observe(this.viewport);
    for (const child of this.viewport.children) this.observer.observe(child);

    for (const thumb of this.el.querySelectorAll("[data-lb-thumb]")) {
      thumb.addEventListener("pointerdown", (event) => this.grab(event, thumb));
    }

    this.measure();
    if (this.messageScroller) this.syncMessageState();
    if (this.sticky && !this.messageScroller) this.toBottom();
    if ((this.messageScroller && !this.messageOpened) || this.pendingTargets.length > 0) {
      this.pendingFrame = requestAnimationFrame(() => {
        if (this.messageScroller && this.messageOpeningHold) this.settleMessageOpeningPosition();
        else if (this.messageScroller) this.applyMessageOpeningPosition();
        else if (this.sticky && this.stuck) this.toBottom();
        this.finishPendingScroll();
      });
    }
  },

  beforeUpdate() {
    if (!this.messageScroller) return;
    this.releaseMessageFrozenOpeningPosition();
    const firstVisible = this.firstVisibleMessageItem();
    this.messageBeforeUpdate = {
      first: this.messageItems()[0]?.getAttribute("data-message-id") || null,
      firstVisible: firstVisible
        ? {
            id: firstVisible.getAttribute("data-message-id"),
            viewportTop: this.messageElementViewportTop(firstVisible),
          }
        : null,
      count: this.messageItems().length,
      height: this.viewport.scrollHeight,
      top: this.viewport.scrollTop,
      atEnd: this.atMessageEnd(),
    };
  },

  updated() {
    // Only while the reader had not scrolled away. Yanking somebody back to the
    // bottom because a message arrived is how a chat log becomes unreadable.
    if (this.messageScroller) {
      // A generation models React remounting the provider. Apply that opening
      // only after LiveView has committed the complete new transcript. An
      // attribute observer runs while a nested patch can still contain rows
      // from the old transcript, which makes the old end position survive a
      // reset and hides the new first row with content-visibility.
      Scroller.refreshMessageScrollerElements.call(this);
      this.refreshMessageScrollerConfig();
      this.animateMessageScrollerItems();
      const updatedOpening = this.applyUpdatedMessageOpeningPosition();
      const opened = updatedOpening ||
        (this.messageOpeningHold
          ? this.settleMessageOpeningPosition()
          : this.applyMessageOpeningPosition());
      // React reconciles a content append in the same layout pass that settles
      // its mount opening. Do the same for a normal LiveView patch: an anchor
      // appended during the hold must not be lost just because the opening
      // also wrote a position. A generation/default-position reset owns the
      // new transcript, so it deliberately does not reuse the old patch
      // snapshot.
      if (!opened || (!updatedOpening && this.messageBeforeUpdate)) {
        this.reconcileMessagePatch();
      }
      // Restore a prepended transcript anchor before reading scrollHeight.
      // An early layout read makes the browser render off-screen
      // content-visibility rows that React keeps at their intrinsic size.
      this.measure();
      this.syncMessageState();
    } else {
      this.measure();
      if (this.sticky && this.stuck) this.toBottom();
    }
  },

  resized() {
    this.measure();
    if (this.messageOpeningFrozenTop !== null) {
      this.restoreMessageFrozenOpeningPosition();
    } else if (this.messageOpeningHold) {
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
    this.messageOpeningInitialTop = Number.isFinite(this.viewport.__liveBaseMessageOpeningTop)
      ? this.viewport.__liveBaseMessageOpeningTop
      : null;
    delete this.viewport.__liveBaseMessageOpeningApplied;
    delete this.viewport.__liveBaseMessageOpeningTop;
    this.messageOpeningHold =
      this.pendingTargets.length > 0 &&
      this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false";
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
    // A LiveView patch can keep this hook instance while replacing every
    // message row. The generation is the explicit signal that this is a new
    // transcript opening, even when its configured position remains `end`.
    this.messageOpeningGeneration =
      this.messageRoot?.getAttribute("data-lb-message-opening-generation") || null;
    if (
      this.messageOpened &&
      this.messageOpeningInitialTop !== null &&
      this.messageRoot?.getAttribute("data-lb-message-opening-hold") === "false"
    ) {
      this.messageOpeningFrozenTop = this.messageOpeningInitialTop;
      this.viewport.scrollTop = this.messageOpeningInitialTop;
      this.restoreMessageFrozenOpeningPosition();
    } else {
      this.messageOpeningFrozenTop = null;
    }
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
      const options = { align, behavior, scrollMargin };

      if (this.messageItems().length === 0) {
        this.pendingMessageScroll = { id, options };
      }
    };
    this.messageRoot?.addEventListener("click", this.onMessageClick);
    this.messageRoot?.addEventListener("message-scroller:scroll-to", this.onMessageScrollTo);
    this.onMessageUserScrollIntent = (event) => {
      if (event.type !== "keydown" || MESSAGE_SCROLL_KEYS.has(event.key)) {
        this.releaseMessageFrozenOpeningPosition();
      }
    };
    for (const type of ["keydown", "pointerdown", "touchmove", "wheel"]) {
      this.viewport.addEventListener(type, this.onMessageUserScrollIntent, { passive: true });
    }
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

  // React starts an IntersectionObserver only when useMessageScrollerVisibility
  // has a subscriber. Most examples do not consume this state. Reading every
  // row rectangle there activates content-visibility:auto rows and changes the
  // transcript geometry. The Storybook outline is this port's subscriber.
  hasMessageVisibilityConsumer() {
    const controller = this.messageRoot?.id;

    if (!controller || typeof document === "undefined") return false;

    return Array.from(document.querySelectorAll("[data-message-scroller-outline]")).some(
      (outline) => outline.getAttribute("data-message-scroller-controller") === controller,
    );
  },

  installMessageVisibilityObserver() {
    if (
      !this.messageVisibilityEnabled ||
      typeof IntersectionObserver === "undefined" ||
      !this.viewport
    ) {
      return;
    }

    this.messageVisibilityObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const id = entry.target.getAttribute("data-message-id");
          if (!id) continue;
          if (entry.isIntersecting) this.messageVisibleIds.add(id);
          else this.messageVisibleIds.delete(id);
        }

        this.syncMessageState();
      },
      {
        root: this.viewport,
        rootMargin: `${-(this.messageMargin + this.messagePreviousPeek)}px 0px 0px 0px`,
        threshold: [0, 0.01, 0.5, 1],
      },
    );
    this.observeMessageVisibilityItems();
  },

  observeMessageVisibilityItems() {
    if (!this.messageVisibilityObserver) return;

    for (const item of this.messageItems()) this.messageVisibilityObserver.observe(item);
  },

  // A reset gives its transcript a new generation key. That is the LiveView
  // form of React remounting the provider: old lazy rows and an old tail
  // spacer must not affect the new opening. Rebind before any opening command
  // so its native end uses only the replacement subtree.
  refreshMessageScrollerElements() {
    const content = this.viewport?.querySelector?.("[data-slot='message-scroller-content']");
    if (!content) return;

    const spacer = content?.querySelector("[data-message-scroller-spacer]");

    if (content === this.messageContent && spacer === this.messageSpacer) return;

    this.messageContent = content;
    this.messageSpacer = spacer;
    this.messageSpacerHeight = spacer?.hidden ? 0 : null;
  },

  // React keeps these values in refs on every provider render. LiveView keeps
  // the same hook instance, so read the current root attributes before a
  // patched message is positioned. Without this refresh, an anchor added after
  // the Previous Context slider changes still uses the old peek value.
  refreshMessageScrollerConfig() {
    this.messageMargin = Number(this.messageRoot?.getAttribute("data-lb-message-scroll-margin")) || 0;
    this.messagePreviousPeek =
      Number(this.messageRoot?.getAttribute("data-lb-message-previous-peek")) || 0;
    this.messageThreshold = Number(this.messageRoot?.getAttribute("data-lb-message-scroll-edge-threshold")) || 8;
  },

  applyUpdatedMessageOpeningPosition() {
    const position = this.messageRoot?.getAttribute("data-lb-message-default-position") || "end";
    const generation =
      this.messageRoot?.getAttribute("data-lb-message-opening-generation") || null;
    const positionChanged = position !== this.messageDefaultPosition;
    const generationChanged = generation !== this.messageOpeningGeneration;
    if (!positionChanged && !generationChanged) return false;

    this.messageDefaultPosition = position;
    this.messageOpeningGeneration = generation;

    this.clearMessageOpeningMaterialization?.();

    // React applies a keyed-provider reset in a layout effect, before lazy
    // rows become their painted height. LiveView receives this after paint, so
    // use the same declared intrinsic transcript end for this one opening.
    if (generationChanged) return this.restartMessageOpeningPosition({ intrinsicLayout: true });
    if (positionChanged && position === "last-anchor") return this.restartMessageOpeningPosition();

    this.messageOpened = false;
    return this.applyMessageOpeningPosition();
  },

  // The pending marker is ignored across ordinary LiveView patches. A reset
  // must therefore recreate it on the client, then keep the opening hold until
  // the new rows have a stable layout. The immediate move prevents a visible
  // jump while the hold protects the exact target from later layout work.
  restartMessageOpeningPosition({ intrinsicLayout = false } = {}) {
    this.messageOpened = false;
    this.messageOpeningFrozenTop = null;
    this.messageOpeningUsesIntrinsicLayout = intrinsicLayout;
    this.clearMessageOpeningMaterialization?.();
    this.pendingTargets = [this.viewport, this.messageRoot].filter(Boolean);
    this.messageOpeningHold =
      this.pendingTargets.length > 0 &&
      this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false";
    this.messageOpeningSawLayout = false;
    this.messageOpeningStableFrames = 0;
    this.messageOpeningTarget = null;
    for (const target of this.pendingTargets) target.setAttribute("data-pending-scroll", "");
    if (this.messageOpeningHold) {
      this.settleMessageOpeningPosition();
    } else {
      this.applyMessageOpeningPosition();
      this.finishPendingScroll();
    }

    return true;
  },

  // Content visibility can move an early opening target after the server
  // records it. Keep that measured target until the reader acts or LiveView
  // starts a new update, which is the same user-intent boundary React uses.
  restoreMessageFrozenOpeningPosition() {
    if (this.messageOpeningFrozenTop === null) return false;

    const target = this.messageOpeningFrozenTop;
    if (Math.abs(this.viewport.scrollTop - target) > SCROLL_POSITION_EPSILON) {
      this.viewport.scrollTop = target;
    }
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
      materialized.push({ item, contentVisibility: item.style.contentVisibility });
      item.style.contentVisibility = "visible";
      if (item === anchor) break;
    }
    this.messageOpeningMaterializedItems = materialized;
  },

  clearMessageOpeningMaterialization() {
    for (const { item, contentVisibility } of this.messageOpeningMaterializedItems || []) {
      item.style.contentVisibility = contentVisibility;
    }
    this.messageOpeningMaterializedItems = null;
  },

  // React writes the default end position in its layout effect, before it
  // reads row geometry for state. An unheld opening must make that same one
  // native write before this hook calls `measure`, which can realize lazy rows.
  applyInitialUnheldMessageOpeningPosition() {
    if (
      this.messageOpened ||
      this.messageOpeningHold ||
      this.messageRoot?.getAttribute("data-lb-message-opening-hold") !== "false"
    ) {
      return false;
    }

    this.messageOpened = true;
    this.clearMessageSpacer();
    this.messageAnchoredItem = null;
    this.markMessageAutoscrolling();
    this.commitMessageScrollState();
    this.viewport.scrollTo({ top: messageEndTarget(this.viewport), behavior: "auto" });
    this.stuck = true;
    this.scheduleMessageScrollStateCommit();
    return true;
  },

  // `scrollToEnd` in the pinned React controller first publishes its current
  // scroll state, then writes the native position, then publishes once more in
  // a frame. The first and second commits read every row's active rectangle.
  // That order is important with content-visibility: Chromium applies scroll
  // anchoring while those rows resolve, not when it merely reads scrollHeight.
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

  // This is the same geometry pass as upstream `getContentBottom`: read every
  // row once, in document order, from the current visual rectangle.
  messageMeasuredContentBottom() {
    const { start, end } = this.messageContentPadding();
    const viewportBounds = this.viewport.getBoundingClientRect();
    let bottom = start + end;

    for (const item of this.messageItems()) {
      const bounds = item.getBoundingClientRect();
      bottom = Math.max(
        bottom,
        bounds.bottom - viewportBounds.top + this.viewport.scrollTop + end,
      );
    }

    return bottom;
  },

  // A transcript can still change its layout after LiveView mounts the new
  // viewport: browser scroll anchoring and content visibility both happen after
  // the first scroll write. Keep the pending hold until the exact target has
  // survived two frames, and restart that check for every observed layout
  // change. This is a stability condition, not a timed delay.
  settleMessageOpeningPosition() {
    if (!this.messageOpeningHold) return false;

    const before = this.viewport.scrollTop;
    this.messageOpened = false;
    const opened = this.applyMessageOpeningPosition();

    if (!opened) return false;

    // Applying a held opening reads its message geometry. That is a complete
    // layout observation even when an existing DOM does not emit ResizeObserver.
    this.messageOpeningSawLayout = true;

    const target = this.viewport.scrollTop;
    const stable =
      this.messageOpeningSawLayout &&
      this.messageOpeningTarget === target &&
      before === target;
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
    if (!this.messageContent) {
      this.messageContent = this.viewport.querySelector("[data-slot='message-scroller-content']");
    }
    return [...(this.messageContent?.children || [])].filter(
      (item) => item instanceof HTMLElement && !item.hasAttribute("data-message-scroller-spacer"),
    );
  },

  messageContentPadding() {
    const style = this.messageContent ? getComputedStyle(this.messageContent) : null;

    return {
      start: Number.parseFloat(style?.paddingBlockStart || style?.paddingTop) || 0,
      end: Number.parseFloat(style?.paddingBlockEnd || style?.paddingBottom) || 0,
    };
  },

  messageElementTop(item) {
    // The pinned React package reads the active visual rectangle. Entry motion
    // therefore participates in the first anchor write and later resize work
    // corrects the position as the motion settles.
    return (
      item.getBoundingClientRect().top -
      this.viewport.getBoundingClientRect().top +
      this.viewport.scrollTop
    );
  },

  messageElementHeight(item) {
    return item.getBoundingClientRect().height;
  },

  messageContentBottom() {
    const { start, end } = this.messageContentPadding();
    let bottom = start + end;

    for (const item of this.messageItems()) {
      bottom = Math.max(
        bottom,
        this.messageElementTop(item) + this.messageElementHeight(item) + end,
      );
    }

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
    return this.viewport.scrollHeight - this.viewport.scrollTop - this.viewport.clientHeight <= this.messageThreshold;
  },

  applyMessageOpeningPosition() {
    const items = this.messageItems();
    if (this.messageOpened || items.length === 0) return false;

    this.messageOpened = true;
    const position = this.messageRoot?.getAttribute("data-lb-message-default-position") || "end";

    if (position === "start") {
      this.scrollMessageToStart();
    } else if (position === "last-anchor") {
      const anchor = items.filter((item) => item.dataset.scrollAnchor === "true").at(-1);

      if (this.messageOpeningHold) {
        this.materializeMessageOpeningAnchor(items, anchor);
      }

      if (
        !anchor ||
        this.messageContentBottom() - this.messageElementTop(anchor) <= this.viewport.clientHeight
      ) {
        this.scrollMessageToEnd({ useIntrinsicLayout: this.messageOpeningUsesIntrinsicLayout });
      } else {
        this.scrollMessageToElement(anchor, { align: "start", keepPreviousPeek: true });
      }
    } else {
      this.scrollMessageToEnd({ useIntrinsicLayout: this.messageOpeningUsesIntrinsicLayout });
    }

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
    const addedBefore = preserves && before.first && first && first !== before.first;

    if (addedBefore) {
      const anchor = before.firstVisible?.id
        ? this.messageContent?.querySelector(
            `[data-message-id=${JSON.stringify(before.firstVisible.id)}]`,
          )
        : null;

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

    const addedAnchors = (items.length > before.count ? items.slice(before.count) : []).filter(
      (item) => item.dataset.scrollAnchor === "true" && !this.messageHandledAnchors.has(item),
    );

    if (addedAnchors.length > 0) {
      // A streaming transcript follows appended messages only while the reader
      // remains at its end. Anchors are still meaningful for non-streaming
      // transcripts, where a new turn opens at its selected anchor.
      if (this.sticky) {
        if (before.atEnd) this.scrollMessageToEnd();
      } else {
        this.scrollMessageToElement(addedAnchors[0], { align: "start", keepPreviousPeek: true });
      }

      for (const anchor of addedAnchors) this.messageHandledAnchors.add(anchor);
    } else if (this.sticky && before.atEnd) {
      this.scrollMessageToEnd();
    }
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
    controls?.finished?.then(
      () => {
        const nativeEnd = Math.max(0, this.viewport.scrollHeight - this.viewport.clientHeight);
        if (Math.abs(this.viewport.scrollTop - nativeEnd) <= SCROLL_POSITION_EPSILON) return;
        if (this.messageAnchoredItem === item && item.isConnected) this.reanchorMessageItem();
      },
      () => {},
    );
  },

  scrollMessageToStart({ behavior = "auto" } = {}) {
    this.clearMessageSpacer();
    this.messageAnchoredItem = null;
    this.viewport.scrollTo({ top: 0, behavior });
    this.stuck = false;
    this.syncMessageState();
    return true;
  },

  scrollMessageToEnd({ behavior = "auto", sync = true, useIntrinsicLayout = false } = {}) {
    this.clearMessageSpacer();
    this.messageAnchoredItem = null;
    this.markMessageAutoscrolling();
    const intrinsicEnd = useIntrinsicLayout
      ? Scroller.messageVirtualContentEnd.call(this)
      : null;
    const top = intrinsicEnd === null
      ? messageEndTarget(this.viewport)
      : Math.max(0, intrinsicEnd - this.viewport.clientHeight);
    this.viewport.scrollTo({ top, behavior });
    this.stuck = true;
    if (sync) this.syncMessageState();
    return true;
  },

  // This is the same public command surface as useMessageScroller. A caller
  // can select a direction, or it can select one message with its alignment.
  // The opening-position example uses the direction form after every render.
  scrollMessageToRequest(
    { id, direction, align = "start", behavior = "auto", scrollMargin } = {},
  ) {
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
    return this.scrollMessageToId(id, { align, behavior, scrollMargin });
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

  scrollMessageToElement(
    item,
    { align = "start", behavior = "auto", scrollMargin, keepPreviousPeek = false } = {},
  ) {
    const margin =
      (scrollMargin ?? this.messageMargin) +
      (keepPreviousPeek ? this.messagePreviousPeek : 0);
    const { start: paddingStart, end: paddingEnd } = this.messageContentPadding();
    const offset = this.messageElementTop(item);
    const height = this.messageElementHeight(item);
    let top = offset - paddingStart - margin;

    if (align === "center") {
      const insetHeight = Math.max(
        0,
        this.viewport.clientHeight - paddingStart - paddingEnd,
      );
      top = offset - paddingStart - (insetHeight - height) / 2 - margin;
    }

    if (align === "end") {
      top = offset - this.viewport.clientHeight + height + paddingEnd + margin;
    }

    if (align === "nearest") {
      const elementBottom = offset + height;
      const visibleStart = this.viewport.scrollTop + paddingStart;
      const visibleEnd = this.viewport.scrollTop + this.viewport.clientHeight - paddingEnd;

      if (offset >= visibleStart && elementBottom <= visibleEnd) {
        top = this.viewport.scrollTop;
      } else if (offset < visibleStart) {
        top = offset - paddingStart - margin;
      } else {
        top = elementBottom - this.viewport.clientHeight + paddingEnd + margin;
      }
    }

    this.updateMessageSpacer(top);
    this.messageAnchoredItem = keepPreviousPeek ? item : null;
    this.viewport.scrollTo({ top: Math.max(0, top), behavior });
    this.stuck = this.atMessageEnd();
    this.syncMessageState();
    return true;
  },

  syncMessageState(contentBottom = null) {
    if (!this.messageScroller) return;
    const atStart = this.atMessageStart();
    const atEnd = contentBottom === null
      ? this.atMessageEnd()
      : contentBottom - this.viewport.scrollTop - this.viewport.clientHeight <= this.messageThreshold;
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

    // Keep this work lazy, as upstream does. A normal Message Scroller does
    // not subscribe to visibility. Its off-screen rows must retain their
    // intrinsic size until the browser needs to paint them.
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

        const visible = tracksVisibilityByLayout && bounds
          ? bounds.bottom > edge && bounds.top < viewportBounds.bottom
          : Boolean(messageId && this.messageVisibleIds.has(messageId));

        if (messageId && visible) visibleMessageIds.push(messageId);
        if (isAnchor && bounds && bounds.top <= edge + 0.5) currentAnchorId = messageId;
      }
    }

    if (currentAnchorId) this.viewport.setAttribute("data-current-anchor-id", currentAnchorId);
    else this.viewport.removeAttribute("data-current-anchor-id");
    if (tracksVisibility) this.syncMessageOutline(currentAnchorId);

    const detail = { start, end, currentAnchorId, visibleMessageIds };
    this.viewport.dispatchEvent(new CustomEvent("message-scroller:state", { bubbles: true, detail }));
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

      for (const choice of outline.querySelectorAll("[data-message-scroller-outline-choice]")) {
        const active = choice.getAttribute("data-message-scroller-anchor-id") === currentAnchorId;
        if (active) choice.setAttribute("aria-current", "location");
        else choice.removeAttribute("aria-current");
      }
    }
  },

  // A footer can live outside the scroll root, so native scroll changes cannot
  // update its server-rendered text. This small binding lets any message
  // scroller copy its state to a named target and reveal the matching status.
  syncMessageScrollStateBindings(state) {
    const controller = this.messageRoot?.id;
    if (!controller) return;

    const status = state || "none";

    for (const target of document.querySelectorAll("[data-lb-message-scroll-state-for]")) {
      if (target.getAttribute("data-lb-message-scroll-state-for") !== controller) continue;

      if (state) target.setAttribute("data-scrollable", state);
      else target.removeAttribute("data-scrollable");

      for (const messageStatus of target.querySelectorAll("[data-lb-message-scroll-status]")) {
        messageStatus.hidden = messageStatus.getAttribute("data-lb-message-scroll-status") !== status;
      }
    }
  },

  updateMessageSpacer(scrollTop) {
    const spacer = this.messageSpacer;
    if (!spacer || !this.messageContent) return;

    const height = Math.max(
      0,
      Math.ceil(Math.max(0, scrollTop) + this.viewport.clientHeight - this.messageSpacerContentEnd()),
    );

    if (this.messageSpacerHeight === height) return;

    this.messageSpacerHeight = height;
    spacer.hidden = height === 0;
    spacer.style.height = `${height}px`;

    if (height > 0) {
      const contentStyle = getComputedStyle(this.messageContent);
      const gap = contentStyle.rowGap === "normal" ? contentStyle.gap : contentStyle.rowGap;
      spacer.style.marginTop = `${-(Number.parseFloat(gap) || 0)}px`;
    } else {
      spacer.style.marginTop = "";
    }
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

    return this.scrollMessageToElement(item, { align: "start", keepPreviousPeek: true });
  },

  toBottom() {
    const offset = Number(this.el.getAttribute("data-lb-bottom-offset")) || 0;
    this.viewport.scrollTop = Math.max(
      0,
      this.viewport.scrollHeight - this.viewport.clientHeight - offset,
    );
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
    for (const type of ["keydown", "pointerdown", "touchmove", "wheel"]) {
      this.viewport.removeEventListener(type, this.onMessageUserScrollIntent);
    }
    this.messageVisibilityObserver?.disconnect();
    this.clearMessageOpeningMaterialization?.();
    for (const item of this.messageItems()) stopMessageEntry(item);
  },

  // The server hides a message viewport until its opening position is ready.
  // Clear the hold only after the first measured move to the newest message.
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

  // Everything the style sheet reads, from one read of the layout.
  measure() {
    const { scrollHeight, clientHeight, scrollWidth, clientWidth } = this.viewport;

    this.axis("y", scrollHeight, clientHeight, this.viewport.scrollTop);
    this.axis("x", scrollWidth, clientWidth, this.viewport.scrollLeft);
  },

  axis(name, total, visible, offset) {
    const overflowing = total > visible + 1;
    const orientation = axis(name);

    for (const scrollbar of this.el.querySelectorAll(
      `[data-slot='scroll-area-scrollbar'][data-orientation='${orientation}']`,
    )) {
      scrollbar.toggleAttribute("hidden", !overflowing);
    }

    const targets = [this.el, ...this.el.querySelectorAll("[data-slot]")];

    for (const target of targets) {
      target.toggleAttribute(`data-has-overflow-${name}`, overflowing);
      target.toggleAttribute(`data-overflow-${name}-start`, overflowing && offset > 0);
      target.toggleAttribute(
        `data-overflow-${name}-end`,
        overflowing && offset + visible < total - 1,
      );
    }

    // The thumb is as much of the track as the viewport is of the content, and
    // it sits that far along. Both are ratios, so neither needs to know how
    // long the track is — the style sheet does, and it is where they are read.
    const track = this.track(name);
    const size = overflowing ? Math.max(MINIMUM_THUMB, (visible / total) * track) : 0;
    const travel = Math.max(0, total - visible);
    const at = travel === 0 ? 0 : (offset / travel) * (track - size);

    const style = this.el.style;
    style.setProperty(`--scroll-area-thumb-${name === "y" ? "height" : "width"}`, `${size}px`);
    style.setProperty(`--scroll-area-overflow-${name}-start`, travel === 0 ? "0" : offset / travel);
    style.setProperty(
      `--scroll-area-overflow-${name}-end`,
      travel === 0 ? "0" : 1 - offset / travel,
    );

    for (const thumb of this.el.querySelectorAll(`[data-lb-thumb][data-orientation='${orientation}']`)) {
      if (name === "y") thumb.style.height = `${size}px`;
      else thumb.style.width = `${size}px`;

      thumb.style.transform =
        name === "y" ? `translate3d(0, ${at}px, 0)` : `translate3d(${at}px, 0, 0)`;
    }
  },

  scrolled() {
    if (this.messageOpeningFrozenTop !== null) {
      this.restoreMessageFrozenOpeningPosition();
      return;
    }

    if (this.sticky) {
      // Within a pixel of the end counts as at the end: a fractional
      // `scrollHeight` means the arithmetic rarely lands exactly on zero.
      const { scrollTop, scrollHeight, clientHeight } = this.viewport;
      this.stuck = scrollHeight - scrollTop - clientHeight <= 1;
    }

    this.mark();
    this.measure();
    if (this.messageScroller) this.syncMessageState();
  },

  // `data-scrolling` for the length of the scroll and a moment after. A class
  // string that fades a scrollbar in reads it, and a scrollbar that vanished
  // between two flicks of a wheel would flicker.
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

  // Dragging the thumb scrolls the viewport, which scrolls this hook, which
  // moves the thumb. The thumb is never moved directly: one direction of
  // travel means the two can never disagree.
  grab(event, thumb) {
    event.preventDefault();
    thumb.setPointerCapture(event.pointerId);

    const vertical = thumb.getAttribute("data-orientation") !== "horizontal";
    const start = vertical ? event.clientY : event.clientX;
    const from = vertical ? this.viewport.scrollTop : this.viewport.scrollLeft;

    const total = vertical ? this.viewport.scrollHeight : this.viewport.scrollWidth;
    const visible = vertical ? this.viewport.clientHeight : this.viewport.clientWidth;
    const track = this.track(vertical ? "y" : "x");
    const size = Math.max(MINIMUM_THUMB, (visible / total) * track);

    const move = (moved) => {
      const travelled = (vertical ? moved.clientY : moved.clientX) - start;
      const room = track - size;
      const scrolled = room === 0 ? 0 : (travelled / room) * (total - visible);

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
  },
};

function axis(name) {
  return name === "y" ? "vertical" : "horizontal";
}
