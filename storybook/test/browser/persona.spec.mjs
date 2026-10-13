import { expect, test } from "@playwright/test";
import { PNG } from "pngjs";

import { visit } from "./live.mjs";

test("a persona loads its Rive visual", async ({ page }) => {
  await visit(page, "/preview/persona/default", "#persona");

  const persona = page.locator("#persona");
  await expect(persona).toHaveAttribute("data-rive-ready", "true", { timeout: 20_000 });
  await expectCanvasFits(persona);

  await expectPainted(persona);
});

test("each Persona variant accepts and retains caller animation state", async ({ page }, testInfo) => {
  testInfo.setTimeout(120_000);
  for (const variant of ["command", "glint", "halo", "mana", "obsidian", "opal"]) {
    const selector = `[data-persona-variant="${variant}"]`;
    await visit(page, `/preview/persona/${variant}`, selector);
    const persona = page.locator(selector);
    await expect(persona).toHaveAttribute("data-persona-variant", variant);
    await expect(persona).toHaveAttribute("data-rive-ready", "true", { timeout: 20_000 });
    await expectCanvasFits(persona);
    await expect(persona).toHaveAttribute("data-persona-state", "idle");
    await page.getByRole("button", { name: "Listening", exact: true }).click();
    await expect(persona).toHaveAttribute("data-persona-state", "listening");
    await expectCanvasFits(persona);
    await expectPainted(persona);
    await expect(page.getByRole("button", { name: "Listening", exact: true })).toHaveAttribute("aria-pressed", "true");
    if (variant === "command") {
      await page.emulateMedia({ colorScheme: "dark" });
      await expectPainted(persona);
      await page.emulateMedia({ colorScheme: "light" });
      await persona.evaluate((element) => { element.style.backgroundColor = "black"; });
      await page.evaluate(() => document.documentElement.classList.add("dark"));
      await expectPainted(persona);
      await persona.evaluate((element) => { element.style.backgroundColor = "white"; });
      await page.evaluate(() => document.documentElement.classList.remove("dark"));
      await expectPainted(persona);
    }
    await page.getByRole("button", { name: "Asleep", exact: true }).click();
    await expect(persona).toHaveAttribute("data-persona-state", "asleep");
    await expect(page.getByRole("button", { name: "Listening", exact: true })).toHaveAttribute("aria-pressed", "false");
  }
});

async function expectPainted(persona) {
  await expect.poll(async () => {
    const image = PNG.sync.read(await persona.locator("canvas").screenshot());
    let painted = 0;
    const background = image.data.subarray(0, 3);

    for (let index = 0; index < image.data.length; index += 4) {
      if (background.some((channel, offset) => Math.abs(image.data[index + offset] - channel) > 10)) {
        painted += 1;
      }
    }

    return painted;
  }).toBeGreaterThan(20);
}

async function expectCanvasFits(persona) {
  const bounds = await persona.evaluate((element) => {
    const frame = element.getBoundingClientRect();
    const canvasElement = element.querySelector("canvas");
    const canvas = canvasElement.getBoundingClientRect();
    return {
      frame: { x: frame.x, y: frame.y, width: frame.width, height: frame.height },
      canvas: { x: canvas.x, y: canvas.y, width: canvas.width, height: canvas.height },
      pixelRatio: canvasElement.width / canvasElement.height,
    };
  });
  for (const dimension of ["x", "y", "width", "height"]) {
    expect(bounds.canvas[dimension]).toBeCloseTo(bounds.frame[dimension], 1);
  }
  expect(bounds.pixelRatio).toBeCloseTo(bounds.frame.width / bounds.frame.height, 1);
}
