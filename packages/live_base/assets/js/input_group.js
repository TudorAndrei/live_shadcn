// The client behavior shared by Input Group parts.
//
// Addons are text-sized click targets. Upstream sends a click on an icon or
// text to the first input in the group, but leaves an actual button to perform
// its own action. Autosize is opt-in because ordinary textareas keep their
// caller-controlled height.

let installed = false;

export function installInputGroupBehavior() {
  if (installed) return;
  installed = true;

  document.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;

    const addon = target.closest("[data-lb-input-group-addon]");

    if (!addon || target.closest("button")) return;
    addon.parentElement?.querySelector("input[data-slot='input-group-control']")?.focus();
  });

  document.addEventListener("input", (event) => autosize(event.target));
  document.addEventListener("focusin", (event) => autosize(event.target));

  const observer = new MutationObserver((records) => {
    for (const record of records) {
      for (const node of record.addedNodes) {
        if (!(node instanceof Element)) continue;
        autosize(node);
        for (const textarea of node.querySelectorAll("textarea[data-lb-autosize]")) {
          autosize(textarea);
        }
      }
    }
  });

  observer.observe(document.documentElement, { childList: true, subtree: true });
  for (const textarea of document.querySelectorAll("textarea[data-lb-autosize]")) autosize(textarea);
}

function autosize(element) {
  if (
    !(element instanceof HTMLTextAreaElement) ||
    !element.hasAttribute("data-lb-autosize")
  ) {
    return;
  }

  element.style.height = "auto";
  element.style.height = `${element.scrollHeight}px`;
}
