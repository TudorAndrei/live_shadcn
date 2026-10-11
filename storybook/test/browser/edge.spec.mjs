import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("an animated edge keeps the caller style", async ({ page }) => {
  await visit(page, "/preview/edge/animated", "#animated-wire");

  await expect(page.locator("#animated-wire")).toHaveCSS("stroke", "rgb(37, 99, 235)");
  const animation = page.locator("animateMotion");
  await expect(animation).toHaveAttribute("path", "M8,16 C 114,16 114,80 220,80");
  await expect(animation).toHaveAttribute("repeatCount", "indefinite");
  const positions = await page.locator("svg").evaluate((svg) => {
    svg.pauseAnimations();
    const marker = svg.querySelector("circle");
    svg.setCurrentTime(0);
    const first = marker.getCTM();
    svg.setCurrentTime(1);
    const second = marker.getCTM();
    return { first: [first.e, first.f], second: [second.e, second.f] };
  });
  expect(positions.second[0]).toBeGreaterThan(positions.first[0]);
  expect(positions.second[1]).toBeGreaterThan(positions.first[1]);
});

test("a temporary edge renders the supplied path with a dashed stroke", async ({ page }) => {
  await visit(page, "/preview/edge/default", "#wire");
  await expect(page.locator("#wire")).toHaveAttribute("d", "M8,16 C 114,16 114,80 220,80");
  await expect(page.locator("#wire")).toHaveCSS("stroke-dasharray", "5px, 5px");
});
