const openExamples = new Set([
  "dropdown-menu.default",
  "dropdown-menu.checkboxes",
  "dropdown-menu.complex",
  "dropdown-menu.radio-group",
]);

/** Put an interactive example in the state that its parity check reviews. */
export async function enterExampleState(page, name) {
  if (!openExamples.has(name)) return;

  const [component] = name.split(".");
  const root = page.locator(`[data-preview='${component}']`);
  const trigger = root.getByRole("button", { name: "Open", exact: true });

  await trigger.click();
  await page.locator("[data-slot='dropdown-menu-content']").waitFor({ state: "visible" });
}
