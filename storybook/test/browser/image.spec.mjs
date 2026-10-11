import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("an image decodes the supplied base64 data and exposes its alternative text", async ({ page }) => {
  await visit(page, "/preview/image/default", "img");
  const image = page.getByRole("img", { name: "A pixel the model drew" });
  await expect(image).toHaveAttribute("src", /^data:image\/png;base64,/);
  await expect.poll(() => image.evaluate((element) => element.complete && element.naturalWidth)).toBe(1);
  await expect.poll(() => image.evaluate((element) => element.naturalHeight)).toBe(1);
});
