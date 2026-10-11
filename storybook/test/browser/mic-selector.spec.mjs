import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the microphone selector opens, chooses a value, and closes", async ({ page }) => {
  await visit(page, "/preview/mic-selector/default", "#mic");

  const trigger = page.locator("#mic-trigger");
  const input = page.locator("#mic-input");

  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(trigger).toHaveRole("button");
  await expect(trigger).toHaveText(/Select microphone/);
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

test("microphone search filters options and keyboard selection skips unavailable devices", async ({ page }) => {
  await visit(page, "/preview/mic-selector/default", "#mic");
  const trigger = page.locator("#mic-trigger");
  const value = page.locator("#mic-input");
  await trigger.press("Enter");
  const search = page.getByRole("combobox", { name: "Search microphones" });
  const builtIn = page.getByRole("option", { name: "Built-in microphone", exact: true });
  const usb = page.getByRole("option", { name: "USB microphone", exact: true });
  await expect(search).toBeFocused();
  await search.fill(" usb ");
  await expect(usb).toBeVisible();
  await expect(builtIn).toBeHidden();
  await search.fill("missing microphone");
  await expect(page.getByText("No microphones found.", { exact: true })).toBeVisible();
  await search.press("Enter");
  await expect(value).toHaveValue("");
  await expect(trigger).toHaveAttribute("aria-expanded", "true");

  await search.fill("");
  await expect(page.getByRole("option", { name: "Wireless microphone (offline)", exact: true })).toHaveAttribute("aria-disabled", "true");
  await search.press("Home");
  await expect(builtIn).toHaveAttribute("aria-selected", "true");
  await search.press("ArrowDown");
  await expect(usb).toHaveAttribute("aria-selected", "true");
  await expect(search).toHaveAttribute("aria-activedescendant", await usb.getAttribute("id"));
  await search.press("Enter");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await expect(trigger).toHaveText(/USB microphone/);
  await expect(value).toHaveValue("usb");
});
