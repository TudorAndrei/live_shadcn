import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const preview = "[data-preview='shadcn-message']";

test("the default Message example keeps alignment, reactions, and typing status", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/default", preview);

  await expect(page.locator(`${preview} [data-slot='message']`)).toHaveCount(4);
  await expect(page.locator(`${preview} [data-slot='message'][data-align='end']`)).toHaveCount(2);
  await expect(page.getByText("Delivered", { exact: true })).toBeVisible();
  await expect(page.locator("[data-slot='bubble-reactions']")).toHaveAttribute(
    "aria-label",
    "Reactions: thumbs up",
  );
  await expect(page.getByRole("status")).toHaveText("Oliver is typing...");
});

test("the avatar Message example keeps pinned image names and grouped content", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/avatar", preview);

  await expect(page.locator(`${preview} [data-slot='message']`)).toHaveCount(3);
  await expect(page.getByAltText("@avatar")).toHaveCount(3);
  await expect(page.getByText("Here's the error from the logs", { exact: true })).toBeVisible();
});

test("the grouped Message example keeps its empty avatar and message group", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/group", preview);

  const group = page.locator(`${preview} [data-slot='message-group']`);
  await expect(group.locator("[data-slot='message']")).toHaveCount(2);
  await expect(group.locator("[data-slot='message-avatar']")).toHaveCount(2);
  await expect(group.getByText("I checked the registry addresses.", { exact: true })).toBeVisible();
});

test("the header and footer Message example keeps its pinned text", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/header-footer", preview);

  await expect(page.locator(`${preview} [data-slot='message-header']`)).toHaveText("Olivia");
  await expect(page.locator(`${preview} [data-slot='message-footer']`)).toHaveText("Read Yesterday");
  await expect(page.getByText("Ping @shadcn if you need help.", { exact: false })).toBeVisible();
});

test("the actions Message example exposes named native buttons", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/actions", preview);

  for (const name of ["Copy", "Like", "Dislike", "Retry"]) {
    await expect(page.getByRole("button", { name, exact: true })).toBeVisible();
    await expect(page.getByRole("button", { name, exact: true })).toHaveAttribute("title", name);
  }

  await expect(page.getByText("Failed to send", { exact: true })).toBeVisible();
});

test("the attachment Message example exposes informative media and Download", async ({ page }) => {
  await visit(page, "/preview/shadcn-message/attachment", preview);

  await expect(page.getByAltText("Workspace")).toBeVisible();
  await expect(page.getByRole("button", { name: "Download", exact: true })).toHaveAttribute(
    "type",
    "button",
  );
  await expect(page.getByText("sales-dashboard.pdf", { exact: true })).toBeVisible();
  await expect(page.getByText("PDF · 2.4 MB", { exact: true })).toBeVisible();
});
