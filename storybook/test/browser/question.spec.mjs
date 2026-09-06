import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const buttonBase =
  "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive";
const buttonSize = "px-4 py-2 has-[>svg]:px-3 h-auto whitespace-normal";
const defaultVariant = "bg-primary text-primary-foreground hover:bg-primary/90";
const outlineVariant =
  "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50";
const defaultOptionClass = [buttonBase, defaultVariant, buttonSize].join(" ");
const outlineOptionClass = [buttonBase, outlineVariant, buttonSize].join(" ");

test("the default Question sends selected values and freeform text", async ({ page }) => {
  await visit(page, "/preview/question/default", "form");

  const form = page.locator("[data-preview='question'] form");
  const authentication = form.getByRole("checkbox", { name: "Authentication" });
  const database = form.getByRole("checkbox", { name: "Database" });
  const answer = form.getByRole("button", { name: "Answer" });

  await expect(form.getByRole("group", { name: "Project features" })).toBeVisible();
  await expect(authentication).toHaveAttribute("aria-checked", "false");
  await expect(authentication).toHaveClass(outlineOptionClass);
  await expect(answer).toBeDisabled();

  await authentication.click();
  await database.click();
  await form.getByLabel("Additional requirements").fill("Deploy in Europe");

  await expect(authentication).toHaveAttribute("aria-checked", "true");
  await expect(authentication).toHaveClass(defaultOptionClass);
  await expect(database).toHaveAttribute("aria-checked", "true");
  await expect(answer).toBeEnabled();
  await answer.click();

  await expect(page.getByText("Answered: authentication, database — Deploy in Europe")).toBeVisible();
});

test("the freeform Question exposes its labelled textbox and official response", async ({ page }) => {
  await visit(page, "/preview/question/freeform", "form");

  const form = page.locator("[data-preview='question'] form");
  const input = form.getByLabel("Project name");
  const answer = form.getByRole("button", { name: "Answer" });

  await expect(input).toHaveAttribute("placeholder", "Project name…");
  await expect(answer).toBeDisabled();
  await input.fill("Atlas");
  await expect(answer).toBeEnabled();
  await answer.click();

  await expect(page.getByText("Answered: Atlas")).toBeVisible();
});

test("the multi-select Question keeps each checked state and submits every selected value", async ({ page }) => {
  await visit(page, "/preview/question/multi-select", "form");

  const form = page.locator("[data-preview='question'] form");
  const authentication = form.getByRole("checkbox", { name: "Authentication" });
  const database = form.getByRole("checkbox", { name: "Database" });
  const continueButton = form.getByRole("button", { name: "Continue" });

  await expect(form.getByRole("group", { name: "Features" })).toBeVisible();
  await authentication.click();
  await database.click();
  await expect(authentication).toHaveClass(defaultOptionClass);
  await expect(database).toHaveClass(defaultOptionClass);

  await authentication.click();
  await expect(authentication).toHaveAttribute("aria-checked", "false");
  await expect(authentication).toHaveClass(outlineOptionClass);
  await expect(database).toHaveAttribute("aria-checked", "true");
  await expect(continueButton).toBeEnabled();
  await continueButton.click();

  await expect(page.getByText("Selected: Database")).toBeVisible();
});

test("the single-select Question follows radio state and returns its selected value", async ({ page }) => {
  await visit(page, "/preview/question/single-select", "form");

  const form = page.locator("[data-preview='question'] form");
  const next = form.getByRole("radio", { name: "Next.js" });
  const nuxt = form.getByRole("radio", { name: "Nuxt" });
  const continueButton = form.getByRole("button", { name: "Continue" });

  await expect(form.getByRole("radiogroup", { name: "Framework" })).toBeVisible();
  await nuxt.click();
  await expect(next).toHaveAttribute("aria-checked", "false");
  await expect(nuxt).toHaveAttribute("aria-checked", "true");
  await expect(nuxt).toHaveClass(defaultOptionClass);
  await expect(continueButton).toBeEnabled();
  await continueButton.click();

  await expect(page.getByText("Selected: Nuxt")).toBeVisible();
});
