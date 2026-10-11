import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("a composed sandbox switches files and preserves its tab when closed", async ({ page }) => {
  await visit(page, "/preview/sandbox/contract", "#code-sandbox");
  const source = page.getByRole("tab", { name: "Source", exact: true });
  const output = page.getByRole("tab", { name: "Output", exact: true });
  await expect(source).toHaveAttribute("aria-selected", "true");
  await expect(page.getByText("export default function App() {}", { exact: true })).toBeVisible();
  await source.focus();
  await source.press("ArrowRight");
  await expect(output).toHaveAttribute("aria-selected", "true");
  await expect(page.getByText("Application ready.", { exact: true })).toBeVisible();

  const trigger = page.getByRole("button", { name: "Generated application", exact: true });
  await trigger.click();
  await expect(output).toBeHidden();
  await trigger.click();
  await expect(output).toHaveAttribute("aria-selected", "true");
  await expect(page.getByText("Application ready.", { exact: true })).toBeVisible();
});
