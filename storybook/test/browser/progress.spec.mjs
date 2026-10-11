import { expect, test } from "@playwright/test";

import { connected, referenceReady } from "./live.mjs";

test("the default example advances after its delay", async ({ page }) => {
  await page.goto("/preview/progress/default");
  await connected(page);

  const progress = page.locator("[data-slot='progress']");
  await expect(progress).toHaveAttribute("aria-valuenow", "13");
  await expect(progress).toHaveAttribute("aria-valuenow", "66");
});

for (const host of ["Phoenix", "React"]) {
  test(`the controlled example shares its value across both native controls on ${host}`, async ({ page }, testInfo) => {
    await page.goto(host === "Phoenix"
      ? "/preview/progress/controlled"
      : `${testInfo.project.use.parityURL}/preview/progress/controlled`);
    await (host === "Phoenix" ? connected(page) : referenceReady(page));

    const sliders = page.locator("input[type='range']");
    const progress = page.getByRole("progressbar");
    await expect(sliders).toHaveCount(2);
    const events = [];
    await page.exposeFunction("recordProgressEvent", event => events.push(event));
    await page.evaluate(() => {
      for (const type of ["input", "change"]) {
        document.addEventListener(type, event => {
          if (!event.target.matches("input[type='range']")) return;
          window.recordProgressEvent({
            type,
            index: [...document.querySelectorAll("input[type='range']")].indexOf(event.target),
            value: event.target.value,
            trusted: event.isTrusted,
          });
        }, true);
      }
    });
    for (let index = 0; index < 2; index += 1) {
      await sliders.nth(index).press("Home");
      await expect(progress).toHaveAttribute("aria-valuenow", "0");
      await sliders.nth(index).press("End");
      await expect(progress).toHaveAttribute("aria-valuenow", "100");
      await expect(sliders.nth(0)).toHaveValue("100");
      await expect(sliders.nth(1)).toHaveValue("100");
    }

    const expectedEvents = [0, 1].flatMap(index => ["0", "100"].flatMap(value =>
      ["input", "change"].map(type => ({ type, index, value, trusted: true }))));
    // React handles these keys with its value callback. Phoenix retains the
    // native input/change contract promised by its range controls.
    if (host === "Phoenix") await expect.poll(() => events).toEqual(expectedEvents);

    const formValues = await sliders.evaluateAll(inputs => {
      const form = document.createElement("form");
      form.id = "progress-native-form";
      document.body.append(form);
      for (const input of inputs) {
        input.name = "amount";
        input.setAttribute("form", form.id);
      }
      return new FormData(form).getAll("amount");
    });
    expect(formValues).toEqual(["100", "100"]);
    await testInfo.attach("scalar-events-and-form.json", {
      body: JSON.stringify({ host, events, formValues }, null, 2),
      contentType: "application/json",
    });
  });
}
