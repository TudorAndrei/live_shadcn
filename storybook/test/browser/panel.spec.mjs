import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("the panel preserves its accessible region and caller-owned content", async ({ page }) => {
  await visit(page, "/preview/panel/contract", "#ai-media-contract");
  const panel = page.getByRole("region", { name: "Graph details" });
  const details = panel.getByRole("button", { name: "Details" });
  await expect(details).toHaveAttribute("aria-expanded", "false");
  await details.click();
  await expect(details).toHaveAttribute("aria-expanded", "true");
  await expect(panel.getByText("2 nodes connected")).toBeVisible();
  await details.press("Space");
  await expect(details).toHaveAttribute("aria-expanded", "false");
  await expect(panel.getByText("2 nodes connected")).toBeHidden();
});
