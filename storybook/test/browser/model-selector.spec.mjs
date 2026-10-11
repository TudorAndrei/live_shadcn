import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("model selector filters a composed dialog and sends the selected model to its caller", async ({ page }) => {
  await page.route("https://models.dev/logos/*.svg", (route) => route.fulfill({
    contentType: "image/svg+xml",
    body: '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><circle cx="6" cy="6" r="5"/></svg>',
  }));
  await visit(page, "/preview/model-selector/contract", "#chatbot-contract");
  const trigger = page.locator("#choose-model-trigger");
  await trigger.click();

  const dialog = page.getByRole("dialog", { name: "Select a model" });
  await expect(dialog).toBeVisible();
  await expect(dialog.getByAltText("anthropic logo")).toHaveAttribute("src", "https://models.dev/logos/anthropic.svg");
  const search = dialog.getByRole("combobox", { name: "Search models" });
  await search.fill("unknown");
  await expect(dialog.getByText("No models found.")).toBeVisible();
  await search.fill("Orion");
  await expect(dialog.getByRole("option")).toHaveCount(1);
  await search.press("Enter");

  await expect(dialog).toBeHidden();
  await expect(trigger).toHaveText("Orion");
  await expect(page.getByRole("status")).toHaveText("Selected model: Orion");
  await expect(page.locator("#chatbot-contract")).toHaveAttribute("data-actions", "1");
});
