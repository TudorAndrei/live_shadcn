import { test } from "@playwright/test";

import { clipboardContract } from "./ai-contracts.mjs";

test.beforeEach(async ({ context }) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
});

test("the terminal copies its output", async ({ page }) => {
  await clipboardContract(
    page,
    "terminal",
    "#copy-output",
    "Compiling 4 files (.ex)",
  );
});
