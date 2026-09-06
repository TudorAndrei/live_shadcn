const MARKER = "[data-lb-attachment-remove='v1']";
let installed = false;

// React stops the remove click before it reaches the hover-card trigger, then
// invokes its own remove callback. LiveView owns `phx-click` at window level.
// Stop the trusted event and replay one synthetic click on the same button.
// Only an untrusted replay reaches the button's nearest `phx-click` binding.
export function installAttachmentRemove() {
  if (installed) return;
  installed = true;

  window.addEventListener(
    "click",
    (event) => {
      if (!event.isTrusted) return;

      const target = event.target instanceof Element ? event.target.closest(MARKER) : null;
      if (!target || !target.hasAttribute("phx-click")) return;

      event.preventDefault();
      event.stopImmediatePropagation();

      target.dispatchEvent(
        new MouseEvent("click", {
          bubbles: true,
          cancelable: true,
          composed: true,
          detail: event.detail,
        }),
      );
    },
    true,
  );
}
