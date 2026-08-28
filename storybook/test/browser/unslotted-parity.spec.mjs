import { expect, test } from "@playwright/test";

const textMetrics = (page, selector) =>
  page.locator(selector).first().evaluate((element) => {
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode()) && !node.textContent.trim()) {}
    const range = document.createRange();
    range.selectNodeContents(node);
    const text = range.getBoundingClientRect();
    const box = element.getBoundingClientRect();
    const child = element.querySelector("svg")?.getBoundingClientRect();
    const pick = ({ x, y, width, height }) => ({ x, y, width, height });
    return {
      box: pick(box),
      child: child ? pick(child) : null,
      text: pick(text),
      value: node.textContent.trim(),
    };
  });

for (const [component, selector] of [
  ["commit", ".font-mono.text-xs"],
  ["file-tree", ".min-w-0"],
]) {
  test(`${component} unslotted text has React geometry`, async ({ page }, testInfo) => {
    await page.goto(`${testInfo.project.use.parityURL}/preview/${component}/default`);
    const react = await textMetrics(page, `[data-preview=${component}] ${selector}`);

    await page.goto(`/preview/${component}/default`);
    const phoenix = await textMetrics(page, `[data-preview=${component}] ${selector}`);

    expect(phoenix).toEqual(react);
  });
}
