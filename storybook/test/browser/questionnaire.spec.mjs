import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const root = (page) => page.locator("[data-preview='questionnaire'] [data-slot='questionnaire']");
const active = (page) => root(page).locator("[data-slot='questionnaire-item'][data-active]");

test("the demo validates, focuses the error, navigates, and submits native answers", async ({ page }) => {
  await visit(page, "/preview/questionnaire/default");
  const form = root(page);

  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "direction");
  await form.getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-invalid", "");
  await expect(active(page).locator("[data-slot='questionnaire-error']")).toHaveAttribute("role", "alert");
  await expect(active(page).locator("input").first()).toBeFocused();

  await active(page).getByLabel("Tool call timeline").check();
  await form.getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "signals");
  await expect(active(page).locator("[data-slot='questionnaire-error']")).toBeHidden();
});

test("shortcuts, arrows, reset, and error associations keep their contracts", async ({ page }) => {
  await visit(page, "/preview/questionnaire/default");
  const form = root(page);

  await active(page).locator("input[value='tool-calls']").focus();
  await page.keyboard.press("A");
  await expect(active(page).locator("input[value='tool-calls']")).toBeChecked();
  await form.press("ArrowRight");
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "signals");
  await expect(active(page)).toBeFocused();
  await page.keyboard.press("ArrowLeft");
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "direction");

  await form.getByRole("button", { name: "Next" }).click();
  await expect(active(page).locator("input").first()).toHaveAttribute("aria-describedby", /questionnaire-signals-description/);
  await form.evaluate((element) => element.reset());
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "direction");
});

test("controlled, conditional, shortcuts, and navigation state use their host controllers", async ({ page }) => {
  await visit(page, "/preview/questionnaire/controlled");
  await expect(root(page)).toHaveAttribute("data-controlled", "");
  await active(page).locator("input[value='component']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(page.locator("[data-preview='questionnaire']").getByRole("status")).toHaveText(
    "Current checkpoint: Verification",
  );
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "checks");

  await visit(page, "/preview/questionnaire/conditional");
  const environment = root(page).locator("[data-questionnaire-name='environment']");
  const conditionalProgress = root(page).locator("[data-slot='questionnaire-progress']");
  await expect(environment).toHaveCount(0);
  await expect(conditionalProgress).toHaveAttribute("aria-valuemax", "2");
  await root(page).locator("input[value='cloud']").check();
  await expect(environment).toHaveCount(1);
  await expect(environment).toBeHidden();
  await expect(conditionalProgress).toHaveAttribute("aria-valuemax", "3");
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "environment");
  await expect(environment).toBeVisible();
  await root(page).getByRole("button", { name: "Previous" }).click();
  await root(page).locator("input[value='local']").check();
  await expect(environment).toHaveCount(0);
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "runtime");
  await expect(conditionalProgress).toHaveAttribute("aria-valuemax", "2");

  await visit(page, "/preview/questionnaire/shortcuts");
  await page.getByLabel("Shortcut style").selectOption("numbers");
  await expect(root(page)).toHaveAttribute("data-shortcuts", "numbers");
  await active(page).locator("input[value='inspect']").focus();
  await page.keyboard.press("1");
  await expect(active(page).locator("input[value='inspect']")).toBeChecked();

  await visit(page, "/preview/questionnaire/navigation-state");
  await expect(active(page)).toHaveAttribute("data-status", "unanswered");
  await expect(root(page).getByRole("button", { name: "Next" })).toBeDisabled();
  await active(page).locator("input[value='files']").check();
  await expect(root(page).getByRole("button", { name: "Next" })).toBeEnabled();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "verification");
  await expect(root(page).getByRole("button", { name: "Previous" })).toBeVisible();
  await expect(root(page).getByRole("button", { name: "Save permissions" })).toBeDisabled();
  await active(page).locator("input[value='tests']").check();
  await expect(root(page).getByRole("button", { name: "Save permissions" })).toBeEnabled();
});

test("validation, resume, and navigation fixtures retain their state contracts", async ({ page }) => {
  await visit(page, "/preview/questionnaire/validation");
  await expect(active(page).locator("[data-slot='questionnaire-progress']")).toHaveText("1 / 2");
  await active(page).locator("input[value='summary']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page).locator("[data-slot='questionnaire-progress']")).toHaveText("2 / 2");
  await active(page).locator("input[value='public']").check();
  await root(page).getByRole("button", { name: "Validate answers" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "detail");
  await expect(active(page).getByText("Public answers need enough context. Choose a complete answer.")).toBeVisible();

  await visit(page, "/preview/questionnaire/resume");
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "verification");
  await active(page).locator("input[value='manual']").check();
  await root(page).getByRole("button", { name: "Reset changes" }).click();
  await expect(active(page).locator("input[value='manual']")).not.toBeChecked();
  await expect(active(page).locator("input[value='tests']")).toBeChecked();
});

test("multiple, freeform, skip, progress, and animated fixtures expose their official controls", async ({ page }) => {
  await visit(page, "/preview/questionnaire/multiple");
  await active(page).locator("input[type='checkbox']").first().check();
  await expect(active(page).locator("input[type='checkbox']").first()).toBeChecked();

  await visit(page, "/preview/questionnaire/freeform");
  const freeform = active(page).locator("[data-slot='questionnaire-input']");
  await freeform.fill("Use the existing API.");
  await expect(freeform).toHaveValue("Use the existing API.");

  await visit(page, "/preview/questionnaire/skip");
  await active(page).locator("input[value='feature']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await root(page).getByRole("button", { name: "Skip" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "review");

  await visit(page, "/preview/questionnaire/progress");
  const progress = root(page).locator("[data-slot='questionnaire-progress']");
  await expect(progress).toHaveAttribute("aria-valuemax", "4");
  await expect(progress).toHaveText("Checkpoint 1 of 4");
  await expect(progress.locator("[data-lb-progress-segment].bg-primary")).toHaveCount(1);
  await active(page).locator("input[value='small']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(progress).toHaveText("Checkpoint 2 of 4");
  await expect(progress).toHaveAttribute("aria-valuenow", "2");
  await expect(progress.locator("[data-lb-progress-segment].bg-primary")).toHaveCount(2);
  await expect(progress.locator("[data-lb-progress-segment].bg-muted")).toHaveCount(2);

  await page.emulateMedia({ reducedMotion: "reduce" });
  await visit(page, "/preview/questionnaire/animated");
  await expect(active(page)).toHaveClass(/data-active:animate-in/);
  await expect(active(page)).toHaveCSS("animation-name", "none");
  await active(page).locator("input[value='implement']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "review");
  await expect(active(page)).toHaveClass(/data-active:animate-in/);
  await expect(active(page)).toHaveCSS("animation-name", "none");

});

test("the card supports number shortcuts, navigation, and the official submit result", async ({ page }) => {
  await visit(page, "/preview/questionnaire/card");
  const form = root(page);

  await active(page).locator("input[value='fix']").focus();
  await page.keyboard.press("1");
  await expect(active(page).locator("input[value='fix']")).toBeChecked();
  await form.getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "output");
  await active(page).locator("input[value='files']").check();
  await form.getByRole("button", { name: "Create task" }).click();

  const toast = page.locator("#questionnaire-card-toasts [data-slot='toast']");
  await expect(toast).toContainText("Agent task created");
  await expect(toast).toContainText("Task: fix · Handoff: files");
});

test("the dialog cancels, escapes, submits, and returns focus to its trigger", async ({ page }) => {
  await visit(page, "/preview/questionnaire/dialog");
  const trigger = page.getByRole("button", { name: "Open clarification" });
  const dialog = page.locator("#questionnaire-dialog-popup");
  await expect(trigger).toHaveAttribute("aria-expanded", "false");
  await trigger.click();
  await expect(trigger).toHaveAttribute("aria-expanded", "true");
  await expect(root(page)).toBeVisible();
  await expect(dialog).toHaveAttribute("data-open", "");
  await expect(dialog).toHaveAttribute("aria-labelledby", "questionnaire-dialog-scope-title");

  await active(page).locator("input[value='component']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "tests");
  await active(page).locator("input[value='full']").check();
  await dialog.getByRole("button", { name: "Cancel" }).click();
  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();

  await trigger.click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "scope");
  await expect(root(page).locator("input:checked")).toHaveCount(0);
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();

  await trigger.click();
  await active(page).locator("input[value='feature']").check();
  await root(page).getByRole("button", { name: "Next" }).click();
  await expect(active(page)).toHaveAttribute("data-questionnaire-name", "tests");
  await expect(dialog).toHaveAttribute("aria-labelledby", "questionnaire-dialog-tests-title");
  await active(page).locator("input[value='package']").check();
  await root(page).getByRole("button", { name: "Send answer" }).click();
  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();

  const toast = page.locator("#questionnaire-dialog-toasts [data-slot='toast']");
  await expect(toast).toContainText("Clarification sent");
  await expect(toast).toContainText("Scope: feature · Verification: package");
});
