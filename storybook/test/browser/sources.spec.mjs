import { test } from "@playwright/test";

import { disclosureContract } from "./ai-contracts.mjs";

test("sources open and close in the browser", async ({ page }) => {
  await disclosureContract(page, "sources", "#citations");
});
