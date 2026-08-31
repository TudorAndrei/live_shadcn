import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("a message scroller completes its opening scroll before it becomes visible", async ({
  page,
}) => {
  await visit(page, "/preview/message-scroller/default", "#messages-viewport");

  const root = page.locator("[data-slot='message-scroller']");
  const viewport = page.locator("#messages-viewport");

  await expect(root).not.toHaveAttribute("data-pending-scroll");
  await expect(viewport).not.toHaveAttribute("data-pending-scroll");

  const distanceToEnd = await viewport.evaluate(
    (element) => element.scrollHeight - element.scrollTop - element.clientHeight,
  );
  expect(distanceToEnd).toBeLessThanOrEqual(1);
});
