// What the browser owns about the navigation.
//
// Two things are true of the sidebar and of no page it navigates to: how far it
// is scrolled, and whether it is collapsed. `LiveBase.Sidebar` says as much —
// whether a reader has the navigation open is a fact about their window rather
// than about the application's data — so the server is never told, and the
// class strings act on `data-state` in the DOM.
//
// A live navigation replaces the LiveView's DOM, and every fact the browser
// owned goes with it: click a component in the sidebar and the sidebar came
// back at the top and open, which is where the server draws it. So this
// remembers the two of them for as long as they are true. `sessionStorage` is
// one tab, and it is gone with the tab, which is the life of a scroll position.
//
// It is not a second copy of anything the server holds. That is the objection
// to keeping state in the browser, and it does not apply to a scroll offset.

// The attributes the client owns, which is the same list `LiveBase.Sidebar`
// tells LiveView to leave alone during a patch. They are remembered by value
// rather than derived, so a sidebar that collapses to a strip of icons and one
// that collapses to nothing both come back the way they went.
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
    // A browser that refuses storage keeps the server's default. That is the
    // page as it was before any of this, not a broken one.
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

  // Every trigger says what the sidebar is doing. A sidebar restored collapsed
  // whose trigger still reads `aria-expanded="true"` tells a screen reader the
  // opposite of what the page shows.
  announce(open) {
    document
      .querySelectorAll(`[data-lb-sidebar='${this.panel.id}']`)
      .forEach((trigger) => trigger.setAttribute("aria-expanded", String(open)));
  },
};
