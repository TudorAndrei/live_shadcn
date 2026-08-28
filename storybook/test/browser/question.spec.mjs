import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("a question changes its selected option", async ({ page }) => {
  await visit(page, "/preview/question/default", "form");

  const next = page.getByRole("radio", { name: "Next.js" });
  const nuxt = page.getByRole("radio", { name: "Nuxt" });
  const submit = page.getByRole("button", { name: "Continue" });

  await expect(next).toHaveAttribute("aria-checked", "false");
  await expect(nuxt).toHaveAttribute("aria-checked", "false");
  await expect(submit).toBeDisabled();

  await nuxt.click();

  await expect(next).toHaveAttribute("aria-checked", "false");
  await expect(nuxt).toHaveAttribute("aria-checked", "true");
  await expect(page.locator("input[name='selected_values[]']")).toHaveValue("Nuxt");
  await expect(submit).toBeEnabled();
});
