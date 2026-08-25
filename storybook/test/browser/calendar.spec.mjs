import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.use({ locale: "fr-FR" });

test("calendar browser locale localizes labels after mount", async ({ page }) => {
  await visit(page, "/preview/calendar/default");
  await expect(page.locator("[data-lb-calendar-month]")).toHaveText("avril 2026");
});
