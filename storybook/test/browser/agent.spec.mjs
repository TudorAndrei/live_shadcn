import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("an agent exposes its tool details and output schema", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 800 });
  await visit(page, "/preview/agent/contract", "#review-tools");
  await expect(page.getByText("Code reviewer", { exact: true })).toBeVisible();
  await expect(page.getByText("Report defects with a file and line number.")).toBeVisible();
  await expect(page.locator("code").filter({ hasText: "{ findings: string[] }" })).toBeVisible();

  const tool = page.getByRole("button", { name: "read_file", exact: true });
  const description = page.getByText("Read a file from the selected repository.");
  const toolBorder = page.locator("#review-tools").locator("..");
  const borderBox = await toolBorder.boundingBox();
  const toolTextLeft = await tool.evaluate((button) => {
    const walker = document.createTreeWalker(button, NodeFilter.SHOW_TEXT);
    let text = walker.nextNode();
    while (text && !text.textContent.trim()) text = walker.nextNode();
    const range = document.createRange();
    range.selectNodeContents(text);
    return range.getBoundingClientRect().left;
  });
  expect.soft(toolTextLeft - borderBox.x, "tool label has an inset from its border")
    .toBeGreaterThanOrEqual(12);

  for (const label of ["Instructions", "Tools", "Output Schema"]) {
    const gap = await page.getByText(label, { exact: true }).evaluate((element) =>
      element.nextElementSibling.getBoundingClientRect().top - element.getBoundingClientRect().bottom,
    );
    expect.soft(gap, `${label} has a gap before its content`).toBeGreaterThanOrEqual(8);
  }

  await expect(description).toBeHidden();
  await tool.press("Enter");
  await expect(description).toBeVisible();
  const descriptionBox = await description.boundingBox();
  expect.soft(descriptionBox.x - borderBox.x, "tool details have an inset from their border")
    .toBeGreaterThanOrEqual(12);
  expect.soft(borderBox.x + borderBox.width - descriptionBox.x - descriptionBox.width,
    "tool details have an inset at the other border").toBeGreaterThanOrEqual(12);
  await expect(page.locator("code").filter({ hasText: "{ path: string }" })).toBeVisible();
  const expectPanelFitsContent = async () => {
    await page.locator("#read-file-tool-panel").evaluate(async (element) => {
      await Promise.allSettled(element.getAnimations({ subtree: true }).map((animation) => animation.finished));
    });
    const panel = await page.locator("#read-file-tool-panel").boundingBox();
    const content = await page.locator("#read-file-tool-panel [data-language]").boundingBox();
    const gap = panel.y + panel.height - content.y - content.height;
    expect(gap, "tool panel keeps padding below its content").toBeGreaterThanOrEqual(12);
    expect(gap, "tool panel ends after its content and padding").toBeLessThanOrEqual(16);
  };
  await expectPanelFitsContent();

  const overflow = await page.locator("[data-preview='agent']").evaluate((preview) => {
    const viewportWidth = document.documentElement.clientWidth;
    return [...preview.querySelectorAll("*")].filter((element) => {
      const box = element.getBoundingClientRect();
      return box.width > 0 && (box.left < 0 || box.right > viewportWidth);
    }).map((element) => element.textContent.trim());
  });
  expect(overflow, "agent content stays inside a 320px viewport").toEqual([]);
  await tool.press(" ");
  await expect(description).toBeHidden();
  await tool.press("Enter");
  await expect(description).toBeVisible();
  await expectPanelFitsContent();
});
