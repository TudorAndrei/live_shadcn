import { test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the commit copies its hash", async ({ page }) => {
  await clipboardContract(page, "commit", "#copy-hash", "a99f1b7");
});
