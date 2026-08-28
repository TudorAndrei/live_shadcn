import { test } from "@playwright/test";

import { disclosureContract } from "./ai-contracts.mjs";

test("reasoning opens and closes in the browser", async ({ page }) => {
  await disclosureContract(page, "reasoning", "#thought");
});
