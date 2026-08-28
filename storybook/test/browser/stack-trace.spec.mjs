import { test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the stack trace copies its raw text", async ({ page }) => {
  await clipboardContract(
    page,
    "stack-trace",
    "#copy-trace",
    "TypeError: Cannot read properties of undefined (reading 'slots')",
    true,
  );
});
