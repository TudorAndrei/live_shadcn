import { test } from "@playwright/test";

import { disclosureContract } from "./ai-contracts.mjs";

test("chain of thought opens and closes in the browser", async ({ page }) => {
  await disclosureContract(page, "chain-of-thought", "#thinking");
});
