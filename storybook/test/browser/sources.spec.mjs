import { expect, test } from "@playwright/test";
import { disclosureContract } from "./ai-contracts.mjs";
import { visit } from "./live.mjs";

test("sources disclose the counted citations and retain their destinations", async ({ page }) => {
  await disclosureContract(page, "sources", "#citations");
  await page.getByRole("button", { name: "Used 3 sources" }).press("Enter");
  const links = page.locator("#citations-panel").getByRole("link");
  await expect(links).toHaveCount(3);
  await expect(links.getByText("Stripe API Documentation")).toBeVisible();
  await expect(page.getByRole("link", { name: "Stripe API Documentation" })).toHaveAttribute("href", "https://stripe.com/docs/api");
  await expect(page.getByRole("link", { name: "GitHub REST API" })).toHaveAttribute("href", "https://docs.github.com/en/rest");
  await expect(links.first()).toHaveAttribute("target", "_blank");
  await expect(links.first()).toHaveAttribute("rel", /noreferrer/);
});

test("custom sources use caller labels and preserve outbound link behavior", async ({ page }) => {
  await visit(page, "/preview/sources/custom", "#custom-citations");
  const trigger = page.getByRole("button", { name: "Using 3 citations" });
  await expect(trigger).toBeVisible();
  await trigger.click();
  const links = page.locator("#custom-citations-panel").getByRole("link");
  await expect(links).toHaveCount(3);
  await expect(links.filter({ hasText: "AWS SDK for JavaScript" })).toHaveAttribute("href", "https://docs.aws.amazon.com/sdk-for-javascript/");
  await expect(links.first()).toHaveAttribute("target", "_blank");
});
