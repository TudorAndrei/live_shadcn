import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the microphone selector opens, chooses a value, and closes", async ({ page }) => {
  await visit(page, "/preview/mic-selector/default", "#mic");

  const trigger = page.getByRole("combobox", { name: "Microphone" });
  const input = page.locator("#mic-input");

  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(trigger).toHaveText(/Select a microphone/);
  await expect(input).toHaveValue("");

  await trigger.click();
  await expect(trigger).toHaveAttribute("aria-expanded", "true");

  const option = page.getByRole("option", { name: "USB microphone" });
  await expect(option).toBeVisible();
  await option.click();

  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(trigger).toHaveText(/USB microphone/);
  await expect(input).toHaveValue("usb");

  await trigger.click();
  await expect(option).toHaveAttribute("aria-selected", "true");
});
