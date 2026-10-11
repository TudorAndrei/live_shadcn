import { expect, test } from "@playwright/test";
import { visit } from "./live.mjs";

test("a schema renders its path, parameters, and nested request and response fields", async ({ page }) => {
  await visit(page, "/preview/schema-display/contract", "#person-schema");
  const schema = page.locator("#person-schema");
  await expect(schema.getByText("POST", { exact: true })).toBeVisible();
  await expect(schema.getByText("/people/{id}", { exact: true })).toBeVisible();
  await expect(schema.getByText("The person identifier.")).toBeVisible();
  await expect(schema.getByText("The public name.")).toBeVisible();
  await expect(schema.getByText("The contact address.")).toBeVisible();

  const profile = schema.locator("summary").filter({ has: page.getByText("profile", { exact: true }) });
  await profile.press("Enter");
  await expect(schema.getByText("The public name.")).toBeHidden();
  await profile.press("Enter");
  await expect(schema.getByText("The public name.")).toBeVisible();
  const parameters = schema.locator("summary").filter({ hasText: "Parameters" });
  await parameters.click();
  await expect(schema.getByText("The person identifier.")).toBeHidden();
});

test("path parameters are marked without interpreting the path as HTML", async ({ page }) => {
  await visit(page, "/preview/schema-display/contract", "#escaped-path");
  const path = page.locator("#escaped-path");
  await expect(path).toHaveText("/search/<script>unsafe</script>/{term}");
  await expect(path.locator("span")).toHaveText("{term}");
  await expect(path.locator("script")).toHaveCount(0);
});
