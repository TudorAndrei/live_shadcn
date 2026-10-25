// Some disclosures reveal more of a visible, clipped region. Other
// disclosures hide their whole region after closing.
export async function waitForCollapsedContent(controlled, timeout = 1000) {
  const clipped = await controlled.evaluateAll(elements => {
    const element = elements[0];
    if (!element) return false;
    const style = getComputedStyle(element);
    return !element.hidden && !element.hasAttribute("data-closed") &&
      element.clientHeight > 0 && element.clientWidth > 0 &&
      element.scrollHeight > element.clientHeight &&
      style.overflowY === "hidden" && Number.isFinite(Number.parseFloat(style.maxHeight));
  });
  await controlled.waitFor({ state: clipped ? "visible" : "hidden", timeout });
}
