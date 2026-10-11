import { expect, test } from "@playwright/test";

import { connected } from "./live.mjs";

test("the tooltip example follows the hovered month", async ({ page }) => {
  await page.goto("/preview/chart/example-tooltip");
  await connected(page);

  const tooltip = page.locator(".recharts-tooltip-wrapper");
  const bars = page.locator("[data-chart-index]");

  await expect(tooltip).toBeHidden();

  await bars.nth(0).hover();
  await expect(tooltip).toBeVisible();
  await expect(tooltip).toContainText("January");
  await expect(tooltip).toContainText("Desktop");
  await expect(tooltip).toContainText("186");
  await expect(tooltip).toContainText("Mobile");
  await expect(tooltip).toContainText("80");

  await bars.nth(5).hover();
  await expect(tooltip).toContainText("June");
  await expect(tooltip).toContainText("214");
  await expect(tooltip).toContainText("140");

  await page.mouse.move(0, 0);
  await expect(tooltip).toBeHidden();
});

test("the tooltip hover geometry matches the official chart", async ({ page }, testInfo) => {
  test.setTimeout(60_000);

  for (const example of ["example-tooltip", "example-legend", "rtl", "demo"]) {
    const paths = [
      `${testInfo.project.use.parityURL}/preview/chart/${example}`,
      `/preview/chart/${example}`,
    ];
    const measurements = [];

    for (const path of paths) {
      await page.goto(path);
      if (path.startsWith("/")) await connected(page);

      const chart = page.locator("[data-preview='chart']");
      const hook = chart.locator("[phx-hook='ChartTooltip'], [phx-hook='ChartDemoTooltip']");
      if ((await hook.count()) > 0) await expect(hook).toHaveAttribute("data-chart-ready", "true");
      await chart.locator(".recharts-rectangle:not(.recharts-tooltip-cursor)").first().hover();
      await chart.locator(".recharts-tooltip-wrapper").waitFor({ state: "visible" });
      await page.waitForTimeout(500);

      measurements.push(await chart.evaluate((root) => {
        const relativeBox = (element) => {
          if (!element) return null;

          const origin = root.getBoundingClientRect();
          const rect = element.getBoundingClientRect();

          return {
            x: rect.x - origin.x,
            y: rect.y - origin.y,
            width: rect.width,
            height: rect.height,
          };
        };

        return {
          tooltip: relativeBox(root.querySelector(".recharts-tooltip-wrapper")),
          cursor: relativeBox(root.querySelector(".recharts-tooltip-cursor")),
        };
      }));
    }

    expect(measurements[1], example).toEqual(measurements[0]);
  }
});

test("the interactive demo tooltip follows the date and connected series", async ({ page }) => {
  await page.goto("/preview/chart/demo");
  await connected(page);
  const tooltip = page.locator(".recharts-tooltip-wrapper");
  const bars = page.locator("[data-chart-date]");
  await bars.first().hover();
  await expect(tooltip).toBeVisible();
  await expect(tooltip).toContainText("Apr 1, 2024");
  await expect(tooltip).toContainText("Page Views");
  await expect(tooltip).toContainText("222");
  await bars.last().hover();
  await expect(tooltip).toContainText("Apr 30, 2024");
  await expect(tooltip).toContainText("454");
  await page.mouse.move(0, 0);
  await expect(tooltip).toBeHidden();
  await page.getByRole("button", { name: "Mobile 7,250" }).click();
  await expect(page.locator("[data-chart-demo-active]")).toHaveAttribute("data-chart-demo-active", "mobile");
  await bars.first().hover();
  await expect(tooltip).toContainText("Apr 1, 2024");
  await expect(tooltip).toContainText("Page Views");
  await expect(tooltip).toContainText("150");
  await page.mouse.move(0, 0);
  await expect(tooltip).toBeHidden();

  await page.setViewportSize({ width: 420, height: 900 });
  const chart = await page.locator("[data-slot='chart']").boundingBox();
  expect(chart.width).toBeLessThan(670);
  for (const [bar, date, value] of [
    [bars.first(), "Apr 1, 2024", "150"],
    [bars.last(), "Apr 30, 2024", "380"],
  ]) {
    await bar.hover();
    await expect(tooltip).toContainText(date);
    await expect(tooltip).toContainText(value);
    const box = await tooltip.boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(chart.x);
    expect(box.x + box.width).toBeLessThanOrEqual(chart.x + chart.width);
    const mark = await bar.boundingBox();
    if (date === "Apr 1, 2024") expect(box.x).toBeGreaterThan(mark.x + mark.width);
    else expect(box.x + box.width).toBeLessThan(mark.x);
  }

});
