import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("the connection joins its endpoints and follows a moved target", async ({ page }) => {
  await visit(page, "/preview/connection/contract", "#ai-media-contract");
  const path = page.getByRole("img", { name: "Connection path" }).locator("path");
  const end = page.getByRole("img", { name: "Connection path" }).locator("circle");
  await expect(path).toHaveAttribute("d", "M8,16 C 114.0,16 114.0,80 220,80");
  await expect(path).toHaveAttribute("fill", "none");
  await expect(end).toHaveAttribute("cx", "220");
  await expect(end).toHaveAttribute("cy", "80");
  await page.getByRole("button", { name: "Move target" }).click();
  await expect(path).toHaveAttribute("d", "M8,16 C 64.0,16 64.0,80 120,80");
  await expect(end).toHaveAttribute("cx", "120");
});
