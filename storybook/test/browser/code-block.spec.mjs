import { test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the code block copies its code", async ({ page }) => {
  await clipboardContract(page, "code-block", "#copy-code", "mix ui.spec");
});
