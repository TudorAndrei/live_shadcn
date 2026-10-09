import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const root = (page) => page.locator("[data-preview='calendar'] [data-slot='calendar']");
const days = (page) => root(page).locator("button[data-lb-calendar-day]");
const selected = (page) => root(page).locator("[role='gridcell'][data-selected]");

test("default supports native single-date selection, focus, and navigation", async ({ page }) => {
  await visit(page, "/preview/calendar/default");
  const calendar = root(page);
  const month = await calendar.getAttribute("data-lb-calendar-month");
  const target = days(page).filter({ hasNot: page.locator("[disabled]") }).nth(8);

  await target.focus();
  await page.keyboard.press("ArrowRight");
  await expect(root(page).locator("button[data-lb-calendar-day]:focus")).toHaveCount(1);
  await page.keyboard.press("Enter");
  await expect(selected(page)).not.toHaveCount(0);
  const navigation = calendar.getByRole("navigation", { name: "Navigation bar", exact: true });
  await navigation.getByRole("button", { name: "Go to the Next Month", exact: true }).click();
  await expect(calendar).not.toHaveAttribute("data-lb-calendar-month", month);
  await expect(navigation.getByRole("button", { name: "Go to the Previous Month", exact: true })).toBeVisible();
});

test("basic starts unselected and supports native single-date selection", async ({ page }) => {
  await visit(page, "/preview/calendar/basic");
  await expect(selected(page)).toHaveCount(0);
  await days(page).filter({ hasNot: page.locator("[disabled]") }).nth(9).click();
  await expect(selected(page)).toHaveCount(1);
});

test("multiple starts empty, adds dates, removes a date, and keeps grid selection semantics", async ({ page }) => {
  await visit(page, "/preview/calendar/multiple");
  const calendar = root(page);
  const first = days(page).nth(0);
  const second = days(page).nth(1);

  await expect(calendar).toHaveAttribute("data-lb-calendar-mode", "multiple");
  await expect(calendar.locator("[role='grid']")).toHaveAttribute("aria-multiselectable", "true");
  await expect(selected(page)).toHaveCount(0);

  await first.click();
  await expect(first.locator("xpath=..")).toHaveAttribute("aria-selected", "true");
  await expect(selected(page)).toHaveCount(1);

  await second.click();
  await expect(second.locator("xpath=..")).toHaveAttribute("aria-selected", "true");
  await expect(selected(page)).toHaveCount(2);

  await first.click();
  await expect(second.locator("xpath=..")).toHaveAttribute("aria-selected", "true");
  await expect(selected(page)).toHaveCount(1);
});

test("range renders two months and exposes start, middle, and end state", async ({ page }) => {
  await visit(page, "/preview/calendar/range");

  await expect(root(page).locator(".rdp-month")).toHaveCount(2);
  await expect(root(page).locator("[data-range-start]")).toHaveCount(1);
  await expect(root(page).locator("[data-range-middle]")).not.toHaveCount(0);
  await expect(root(page).locator("[data-range-end]")).toHaveCount(1);
});

test("caption dropdowns change the visible month and year", async ({ page }) => {
  await visit(page, "/preview/calendar/caption");
  const calendar = root(page);
  const month = await calendar.getAttribute("data-lb-calendar-month");

  await calendar.locator("select[data-lb-calendar-caption='month']").first().selectOption({ index: 0 });
  await expect(calendar).not.toHaveAttribute("data-lb-calendar-month", month);
  await expect(calendar.locator("select[data-lb-calendar-caption='year']").first()).toBeVisible();
});

test("preset actions set a selected date and navigate to its month", async ({ page }) => {
  await visit(page, "/preview/calendar/presets");
  const calendar = root(page);

  await page.getByRole("button", { name: "In 2 weeks" }).click();
  await expect(selected(page)).toHaveCount(1);
  await expect(calendar.locator(".rdp-month")).toHaveCount(1);
});

test("time keeps the native labeled time controls", async ({ page }) => {
  await visit(page, "/preview/calendar/time");

  await expect(page.getByLabel("Start Time")).toHaveValue("10:30:00");
  await expect(page.getByLabel("End Time")).toHaveValue("12:30:00");
  await expect(page.getByLabel("Start Time")).toHaveAttribute("step", "1");
});

test("booked dates are disabled, visible, and never become selected", async ({ page }) => {
  await visit(page, "/preview/calendar/booked-dates");
  const booked = root(page).locator("[role='gridcell'][data-disabled] button").first();

  await expect(booked).toBeDisabled();
  await expect(booked.locator("xpath=..")).toHaveClass(/line-through/);
  await booked.click({ force: true });
  await expect(booked.locator("xpath=..")).not.toHaveAttribute("data-selected", "");
});

test("custom days show exact weekday and weekend prices", async ({ page }) => {
  await visit(page, "/preview/calendar/custom-days");
  const prices = root(page).locator("[data-lb-calendar-day] > span");

  await expect(prices.filter({ hasText: "$100" })).not.toHaveCount(0);
  await expect(prices.filter({ hasText: "$120" })).not.toHaveCount(0);
  await expect(root(page).locator("select[data-lb-calendar-caption='month']")).toHaveCount(1);
});

test("week numbers retain the week column and selected day", async ({ page }) => {
  await visit(page, "/preview/calendar/week-numbers");

  await expect(root(page).locator("th.rdp-week_number_header")).toHaveCount(1);
  await expect(root(page).locator("td.rdp-week_number")).not.toHaveCount(0);
  await expect(selected(page)).toHaveCount(1);
});

test("Hijri retains its Persian calendar and RTL contracts", async ({ page }) => {
  await visit(page, "/preview/calendar/hijri");
  await expect(root(page)).toHaveAttribute("data-lb-calendar-system", "persian");
  await expect(root(page)).toHaveAttribute("dir", "rtl");
  await expect(root(page).locator(".rdp-caption_label")).toContainText(/[۰-۹]/);
  const calendar = root(page);
  const month = await calendar.getAttribute("data-lb-calendar-month");
  const navigation = calendar.getByRole("navigation", { name: "نوار ناوبری", exact: true });
  await navigation.getByRole("button", { name: "رفتن به ماه بعد", exact: true }).click();
  await expect(calendar).not.toHaveAttribute("data-lb-calendar-month", month);
  await expect(navigation.getByRole("button", { name: "رفتن به ماه قبل", exact: true })).toBeVisible();
});

test("RTL retains its caption and selected-date contracts", async ({ page }) => {
  await visit(page, "/preview/calendar/rtl");
  await expect(root(page)).toHaveAttribute("dir", "rtl");
  await expect(root(page).locator("select[data-lb-calendar-caption='month']")).toHaveCount(1);
  await expect(selected(page)).toHaveCount(1);
  const calendar = root(page);
  const month = await calendar.getAttribute("data-lb-calendar-month");
  const navigation = calendar.getByRole("navigation", { name: "شريط التنقل", exact: true });
  await navigation.getByRole("button", { name: "اذهب إلى الشهر التالي", exact: true }).click();
  await expect(calendar).not.toHaveAttribute("data-lb-calendar-month", month);
  await expect(navigation.getByRole("button", { name: "اذهب إلى الشهر السابق", exact: true })).toBeVisible();
});
