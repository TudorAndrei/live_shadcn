import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("an animated edge keeps the caller style", async ({ page }) => {
  await visit(page, "/preview/edge/animated", "#animated-wire");

  await expect(page.locator("#animated-wire")).toHaveCSS("stroke", "rgb(37, 99, 235)");
});
