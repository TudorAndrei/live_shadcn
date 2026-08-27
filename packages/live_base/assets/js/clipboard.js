// The clipboard hook.
//
// Copying is `navigator.clipboard.writeText`, which exists in a browser and
// nowhere else. The server cannot do it, cannot be told to do it, and has no
// use for knowing that it happened — so nothing here is pushed and nothing is
// asked for.
//
// What the hook owns is the two seconds afterwards, in which the copy icon is a
// check. The server cannot draw that state because it does not know it, so the
// reviewed port draws both icons and hides one:
//
//   data-lb-clipboard   on the button: the text to copy
//   data-lb-timeout     how long the copied state lasts, in milliseconds
//   data-lb-state       on each branch: `copied` or `idle`
//
// And one it writes: `data-lb-ready`, once it is listening. A button whose page
// has not connected yet copies nothing, and this is what says so — to a style
// sheet, and to a test that would otherwise click into that window.
//
// The one it does not hide is the one the server can be sure of: a page that
// has just loaded has copied nothing. `LiveBase.Clipboard.owned_attributes/1`
// is what stops the next patch from putting that guess back over this.
//
// A page that wants to know listens for `lb:copied` and `lb:copy-error`, which
// is upstream's `onCopy` and `onError` without a round trip.

// What upstream's `timeout` prop defaults to, for markup that declares none.
const TIMEOUT = 2000;

export const Clipboard = {
  mounted() {
    this.el.addEventListener("click", () => this.copy());
    this.el.toggleAttribute("data-lb-ready", true);
  },

  destroyed() {
    clearTimeout(this.timer);
  },

  async copy() {
    // A clipboard needs a secure context, and a page served over plain HTTP has
    // none. Saying so beats a button that silently does nothing.
    if (!navigator?.clipboard?.writeText) {
      return this.announce("lb:copy-error", { error: "the clipboard API is not available" });
    }

    try {
      await navigator.clipboard.writeText(this.el.getAttribute("data-lb-clipboard") ?? "");
    } catch (error) {
      return this.announce("lb:copy-error", { error: String(error) });
    }

    this.show("copied");
    this.announce("lb:copied", {});

    // One timer, restarted. Two copies in a row otherwise leave the first
    // timeout running, and the check goes back to a copy icon early.
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.show("idle"), this.timeout());
  },

  timeout() {
    return Number(this.el.getAttribute("data-lb-timeout")) || TIMEOUT;
  },

  // The attribute, never the `hidden` property. `hidden` is `HTMLElement`'s,
  // and both branches here are an `<svg>`: assigning to `element.hidden` on one
  // sets a JavaScript property nothing reads and leaves the attribute — and the
  // icon — exactly as it was.
  show(state) {
    for (const branch of this.el.querySelectorAll("[data-lb-state]")) {
      branch.toggleAttribute("hidden", branch.getAttribute("data-lb-state") !== state);
    }
  },

  announce(name, detail) {
    this.el.dispatchEvent(new CustomEvent(name, { bubbles: true, detail }));
  },
};
