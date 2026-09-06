const positions = new Set(["start", "end", "last-anchor"]);

export function openingPositionRequest(position) {
  if (position === "last-anchor") {
    return {
      id: "open-3",
      align: "start",
      behavior: "auto",
      scrollMargin: 64,
    };
  }

  if (position === "start" || position === "end") {
    return { direction: position, behavior: "auto" };
  }

  return null;
}

function dispatchOpeningPosition(target, position) {
  const request = openingPositionRequest(position);
  if (!request || !target) return false;

  target.dispatchEvent(new CustomEvent("message-scroller:scroll-to", { detail: request }));
  return true;
}

export const OpeningPosition = {
  mounted() {
    this.openingPositionTarget = () =>
      document.getElementById(this.el.getAttribute("data-lb-opening-position-target"));

    this.dispatchOpeningPosition = (position) => {
      return dispatchOpeningPosition(this.openingPositionTarget(), position);
    };

    this.applyOpeningPosition = () => {
      const tab = this.el.querySelector("[role='tab'][aria-selected='true']");
      const prefix = `${this.el.id}-tab-`;
      const position = tab?.id.startsWith(prefix) ? tab.id.slice(prefix.length) : null;
      this.dispatchOpeningPosition(position);
    };

    this.cancelOpeningPositionWait = () => {
      this.openingPositionObserver?.disconnect();
      this.openingPositionObserver = null;
    };

    this.dispatchSelectedOpeningPositionWhenSettled = () => {
      const target = this.openingPositionTarget();
      if (!target || !target.hasAttribute?.("data-pending-scroll")) {
        this.applyOpeningPosition();
        return;
      }

      if (typeof MutationObserver !== "function") return;

      const observer = new MutationObserver(() => {
        if (
          this.openingPositionObserver !== observer ||
          target.hasAttribute("data-pending-scroll")
        ) {
          return;
        }

        observer.disconnect();
        this.openingPositionObserver = null;
        this.applyOpeningPosition();
      });

      this.openingPositionObserver = observer;
      observer.observe(target, {
        attributes: true,
        attributeFilter: ["data-pending-scroll"],
      });
    };

    this.scheduleOpeningPosition = (position = null) => {
      cancelAnimationFrame(this.openingPositionFrame);
      this.cancelOpeningPositionWait();
      this.openingPositionFrame = requestAnimationFrame(() => {
        this.openingPositionFrame = null;
        if (position) this.dispatchOpeningPosition(position);
        else this.dispatchSelectedOpeningPositionWhenSettled();
      });
    };

    this.onClick = (event) => {
      const tab = event.target.closest("[role='tab']");
      if (!tab || !this.el.contains(tab)) return;

      const prefix = `${this.el.id}-tab-`;
      const position = tab.id.startsWith(prefix) ? tab.id.slice(prefix.length) : null;
      if (!positions.has(position)) return;

      this.pushEvent("message_scroller_opening_position", { position });
      this.scheduleOpeningPosition(position);
    };

    this.el.addEventListener("click", this.onClick);
    this.scheduleOpeningPosition();
  },

  updated() {
    this.scheduleOpeningPosition();
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    cancelAnimationFrame(this.openingPositionFrame);
    this.cancelOpeningPositionWait();
  },
};
