import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const preview = (page) => page.locator("[data-preview='attachments']");
const removeButtons = (page) => preview(page).getByRole("button", { name: "Remove" });

async function open(page, example) {
  await visit(page, `/preview/attachments/${example}`, "[data-preview='attachments']");
}

test.describe("attachments", () => {
  test("the image grid renders image alternatives and removes one image", async ({ page }) => {
    await open(page, "default");

    await expect(preview(page).getByAltText("mountain-landscape.jpg")).toBeVisible();
    await expect(preview(page).getByAltText("ocean-sunset.jpg")).toBeVisible();
    await expect(removeButtons(page)).toHaveCount(4);

    await removeButtons(page).first().click();

    await expect(preview(page).getByAltText("mountain-landscape.jpg")).toHaveCount(0);
    await expect(removeButtons(page)).toHaveCount(3);
  });

  test("the list shows labels and media types, then removes one row", async ({ page }) => {
    await open(page, "list");

    await expect(preview(page).getByText("API Documentation")).toBeVisible();
    await expect(preview(page).getByText("audio/mpeg")).toBeVisible();
    await expect(removeButtons(page)).toHaveCount(5);

    await removeButtons(page).first().click();

    await expect(preview(page).getByText("mountain-landscape.jpg")).toHaveCount(0);
    await expect(removeButtons(page)).toHaveCount(4);
  });

  test("the inline hover card gives each remove control an accessible name", async ({ page }) => {
    await open(page, "inline");

    await expect(removeButtons(page)).toHaveCount(4);
    await expect(
      preview(page).locator("[data-slot='hover-card-trigger']").getByText("React Documentation"),
    ).toBeVisible();

    await preview(page).locator("#attachment-inline-mountain-landscape-trigger").hover();
    const firstContent = preview(page).locator("#attachment-inline-mountain-landscape-popup");
    await expect(firstContent).toBeVisible();
    await expect(firstContent).toContainText(
      "image/jpeg",
    );

    await removeButtons(page).first().click();

    await expect(preview(page).getByText("mountain-landscape.jpg")).toHaveCount(0);
    await expect(removeButtons(page)).toHaveCount(3);
    await expect(preview(page).locator("[data-slot='hover-card-content']:visible")).toHaveCount(0);
    await expect(preview(page).locator("#attachment-inline-mountain-landscape-popup")).toHaveCount(0);
  });

  test("an inline remove keeps a closed card closed and sends one caller action", async ({ page }) => {
    await open(page, "inline");

    await expect(preview(page).locator("[data-slot='hover-card-content']:visible")).toHaveCount(0);
    await expect(preview(page)).toHaveAttribute(
      "data-attachment-remove-count",
      "0",
    );

    await removeButtons(page).first().click();

    await expect(preview(page).getByText("mountain-landscape.jpg")).toHaveCount(0);
    await expect(removeButtons(page)).toHaveCount(3);
    await expect(preview(page).locator("[data-slot='hover-card-content']:visible")).toHaveCount(0);
    await expect(preview(page).locator("#attachment-inline-mountain-landscape-popup")).toHaveCount(0);
    await expect(preview(page)).toHaveAttribute(
      "data-attachment-remove-count",
      "1",
    );
  });
});
