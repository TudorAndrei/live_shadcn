import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const picker = (page, id) => ({
  trigger: page.locator(`#${id}-trigger`),
  popup: page.locator(`#${id}-popup`),
  calendar: page.locator(`#${id}-calendar`),
});

const day = (calendar, value) =>
  calendar.locator(`button[data-lb-calendar-day][data-day='${value}']:not([disabled])`);

const selectedDay = (calendar, value) =>
  calendar.locator(`[role='gridcell'][data-day='${value}'][data-selected]`);

const isoInCurrentYear = async (page, month, date) =>
  page.evaluate(
    ({ month, date }) => `${new Date().getFullYear()}-${String(month).padStart(2, "0")}-${String(date).padStart(2, "0")}`,
    { month, date },
  );

const utcIsoOffset = async (page, days) =>
  page.evaluate((offset) => {
    const now = new Date();
    const utc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + offset));
    return utc.toISOString().slice(0, 10);
  }, days);

test("the default Date Picker selects a date, stays open, and closes outside", async ({ page }) => {
  await visit(page, "/preview/date-picker/default", "#date-picker-demo-trigger");
  const { trigger, popup, calendar } = picker(page, "date-picker-demo");

  await expect(popup).toBeHidden();
  await trigger.click();
  await expect(popup).toBeVisible();

  const target = calendar.locator("button[data-lb-calendar-day]:not([disabled])").nth(10);
  const selected = await target.getAttribute("data-day");
  expect(selected).toBeTruthy();
  await target.click();
  await expect(selectedDay(calendar, selected)).toHaveCount(1);
  await expect(trigger).not.toContainText("Pick a date");
  await expect(popup).toBeVisible();

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
});

test("the basic Date Picker retains its selected date when it reopens", async ({ page }) => {
  await visit(page, "/preview/date-picker/basic", "#date-picker-basic-trigger");
  const { trigger, popup, calendar } = picker(page, "date-picker-basic");

  await trigger.click();
  const target = calendar.locator("button[data-lb-calendar-day]:not([disabled])").nth(11);
  const selected = await target.getAttribute("data-day");
  expect(selected).toBeTruthy();
  await target.click();
  await expect(selectedDay(calendar, selected)).toHaveCount(1);
  await expect(trigger).not.toContainText("Pick a date");

  await page.locator("body").click({ position: { x: 5, y: 5 } });
  await expect(popup).toBeHidden();
  await trigger.click();
  await expect(selectedDay(calendar, selected)).toHaveCount(1);
});

test("the range Date Picker replaces its range with two selected endpoints", async ({ page }) => {
  await visit(page, "/preview/date-picker/range", "#date-picker-range-trigger");
  const { trigger, popup, calendar } = picker(page, "date-picker-range");
  const first = await isoInCurrentYear(page, 1, 5);
  const last = await isoInCurrentYear(page, 1, 10);

  await trigger.click();
  await expect(popup).toBeVisible();
  await day(calendar, first).click();
  await expect(selectedDay(calendar, first)).toHaveCount(1);
  await day(calendar, last).click();
  await expect(calendar.locator(`button[data-day='${first}'][data-range-start]`)).toHaveCount(1);
  await expect(calendar.locator(`button[data-day='${last}'][data-range-end]`)).toHaveCount(1);
  await expect(trigger).toContainText("Jan 05");
  await expect(trigger).toContainText("Jan 10");
});

test("the Date of birth Picker selects one date and closes", async ({ page }) => {
  await visit(page, "/preview/date-picker/dob", "#date-picker-dob-trigger");
  const { trigger, popup, calendar } = picker(page, "date-picker-dob");

  await trigger.click();
  await expect(calendar.locator("select[data-lb-calendar-caption='month']")).toBeVisible();
  const target = calendar.locator("button[data-lb-calendar-day]:not([disabled])").nth(12);
  await target.click();
  await expect(popup).toBeHidden();
  await expect(trigger).not.toContainText("Select date");
});

test("the typed Date Picker retains invalid text, opens with ArrowDown, and formats a calendar choice", async ({ page }) => {
  await visit(page, "/preview/date-picker/input", "#date-required");
  const input = page.locator("#date-required");
  const { popup, calendar } = picker(page, "date-picker-input");

  await expect(input).toHaveValue("June 01, 2025");
  await input.fill("not a date");
  await expect(input).toHaveValue("not a date");
  await input.press("ArrowDown");
  await expect(popup).toBeVisible();
  await expect(selectedDay(calendar, "2025-06-01")).toHaveCount(1);

  await day(calendar, "2025-06-02").click();
  await expect(popup).toBeHidden();
  await expect(input).toHaveValue("June 02, 2025");
  await expect(input).toBeFocused();
});

test("the Date and time Picker keeps its time after a date selection", async ({ page }) => {
  await visit(page, "/preview/date-picker/time", "#date-picker-time-trigger");
  const time = page.locator("#time-picker-optional");
  const { trigger, popup, calendar } = picker(page, "date-picker-time");

  await expect(time).toHaveValue("10:30:00");
  await time.fill("11:45:30");
  await trigger.click();
  const target = calendar.locator("button[data-lb-calendar-day]:not([disabled])").nth(13);
  await target.click();
  await expect(popup).toBeHidden();
  await expect(trigger).not.toContainText("Select date");
  await expect(time).toHaveValue("11:45:30");
});

test("the natural-language Date Picker parses text, preserves invalid text, and opens with ArrowDown", async ({ page }) => {
  await visit(page, "/preview/date-picker/natural-language", "#date-optional");
  const input = page.locator("#date-optional");
  const published = page.locator("#date-optional").locator("xpath=ancestor::*[@data-slot='field'][1]").locator("span.font-medium");
  const { popup, calendar } = picker(page, "date-picker-natural-language");

  // The React source calculates this label with `new Date()` and LiveView
  // calculates it with `Date.utc_today()`. The verification browser must use
  // UTC so both values stay equal at local midnight.
  expect(await page.evaluate(() => Intl.DateTimeFormat().resolvedOptions().timeZone)).toBe("UTC");

  const tomorrow = await utcIsoOffset(page, 1);
  const initialPublished = (await published.textContent())?.trim();
  expect(initialPublished).toBeTruthy();

  await input.fill("tomorrow");
  await expect(input).toHaveValue("tomorrow");
  await input.press("ArrowDown");
  await expect(popup).toBeVisible();
  await expect(selectedDay(calendar, tomorrow)).toHaveCount(1);
  await expect(published).not.toHaveText(initialPublished);

  await input.fill("not a date");
  await expect(input).toHaveValue("not a date");
  await expect(selectedDay(calendar, tomorrow)).toHaveCount(1);

  await day(calendar, tomorrow).click();
  await expect(popup).toBeHidden();
  await expect(input).toBeFocused();
});

test("the RTL Date Picker keeps Arabic direction and formats the selected date in Arabic", async ({ page }) => {
  await visit(page, "/preview/date-picker/rtl", "#date-picker-rtl-trigger");
  const { trigger, popup, calendar } = picker(page, "date-picker-rtl");

  await expect(trigger).toHaveAttribute("dir", "rtl");
  await expect(trigger).toContainText("اختر تاريخًا");
  await trigger.click();
  await expect(popup).toHaveAttribute("dir", "rtl");
  await expect(calendar).toHaveAttribute("dir", "rtl");
  await expect(calendar).toHaveAttribute("data-lb-calendar-locale", "ar");

  const target = calendar.locator("button[data-lb-calendar-day]:not([disabled])").nth(14);
  const selected = await target.getAttribute("data-day");
  expect(selected).toBeTruthy();
  await target.click();
  await expect(selectedDay(calendar, selected)).toHaveCount(1);
  await expect(trigger).toContainText(/[0-9]/);
});
