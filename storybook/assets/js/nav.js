// What the browser owns about the navigation: how far the sidebar is scrolled,
// and whether it is collapsed. The server is never told either — whether a
// reader has the navigation open is a fact about their window — and a live
// navigation replaces the LiveView's DOM, so this remembers them.
//
// `sessionStorage` is one tab and goes with the tab, which is the life of a
// scroll position. It holds no copy of anything the server knows.

// The attributes the client owns, the same list `LiveBase.Sidebar` tells
// LiveView to leave alone during a patch. Remembered by value rather than
// derived, so a sidebar that collapses to icons and one that collapses to
// nothing both come back the way they went.
const OWNED = ["data-state", "data-collapsible"];

const read = (key) => {
  try {
    return sessionStorage.getItem(key);
  } catch {
    return null;
  }
};

const write = (key, value) => {
  try {
    sessionStorage.setItem(key, value);
  } catch {
    // A browser that refuses storage keeps the server's default.
  }
};

export const Nav = {
  mounted() {
    this.panel = this.el.closest('[data-slot="sidebar"]');
    this.restore();
    this.watch();
  },

  destroyed() {
    this.observer?.disconnect();
  },

  key(part) {
    return `nav:${this.panel?.id || this.el.id}:${part}`;
  },

  restore() {
    this.el.scrollTop = Number(read(this.key("scroll")) || 0);

    const saved = JSON.parse(read(this.key("state")) || "null");
    if (!this.panel || !saved) return;

    OWNED.forEach((name, i) => this.panel.setAttribute(name, saved[i]));
    this.announce(saved[0] === "expanded");
  },

  watch() {
    let queued = false;

    this.el.addEventListener(
      "scroll",
      () => {
        if (queued) return;
        queued = true;
        requestAnimationFrame(() => {
          queued = false;
          write(this.key("scroll"), this.el.scrollTop);
        });
      },
      { passive: true },
    );

    if (!this.panel) return;

    this.observer = new MutationObserver(() => {
      const owned = OWNED.map((name) => this.panel.getAttribute(name) ?? "");
      write(this.key("state"), JSON.stringify(owned));
    });

    this.observer.observe(this.panel, { attributeFilter: OWNED });
  },

  // Every trigger says what the sidebar is doing, so a restored state has to
  // reach them or `aria-expanded` contradicts the page.
  announce(open) {
    document
      .querySelectorAll(`[data-lb-sidebar='${this.panel.id}']`)
      .forEach((trigger) => trigger.setAttribute("aria-expanded", String(open)));
  },
};
