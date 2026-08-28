import { expect, test } from "@playwright/test";
import { PNG } from "pngjs";

import { visit } from "./live.mjs";

test("a persona loads its Rive visual", async ({ page }) => {
  await visit(page, "/preview/persona/default", "#persona");

  const persona = page.locator("#persona");
  await expect(persona).toHaveAttribute("data-rive-ready", "true", { timeout: 20_000 });

  await page.waitForTimeout(250);
  const image = PNG.sync.read(await persona.locator("canvas").screenshot());
  let painted = 0;

  for (let index = 0; index < image.data.length; index += 4) {
    const red = image.data[index];
    const green = image.data[index + 1];
    const blue = image.data[index + 2];
    if (red < 245 || green < 245 || blue < 245) painted += 1;
  }

  expect(painted).toBeGreaterThan(20);
});
