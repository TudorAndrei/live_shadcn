import { chromium } from "@playwright/test";
const browser = await chromium.launch();
for (const [name, port] of [["phoenix", 4301], ["react", 4302]]) {
  const page = await browser.newPage();
  await page.goto(`http://127.0.0.1:${port}/preview/prompt-input/default`);
  await page.waitForTimeout(600);
  const info = await page.evaluate(() => {
    const el = document.querySelector('[data-slot="input-group-addon"]');
    return el && { cls: el.className, jc: getComputedStyle(el).justifyContent };
  });
  console.log(name, JSON.stringify(info, null, 1));
  await page.close();
}
await browser.close();
