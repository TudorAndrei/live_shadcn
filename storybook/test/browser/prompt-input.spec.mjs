import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test.describe("prompt input", () => {
  test("Enter submits and Shift+Enter adds a new line", async ({ page }) => {
    await visit(page, "/preview/prompt-input/default", "textarea");

    const textarea = page.locator("textarea");
    const submit = page.getByRole("button", { name: "Submit" });

    await expect(submit).toHaveAttribute("type", "submit");

    await page.locator("form").evaluate((form) => {
      window.promptSubmits = 0;
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        window.promptSubmits += 1;
      });
    });

    await textarea.fill("First line");
    await textarea.press("Shift+Enter");
    await expect(textarea).toHaveValue("First line\n");
    expect(await page.evaluate(() => window.promptSubmits)).toBe(0);

    await textarea.press("Enter");
    await expect.poll(() => page.evaluate(() => window.promptSubmits)).toBe(1);
    await expect(textarea).toHaveValue("First line\n");
  });

  test("Enter does not submit through a disabled button", async ({ page }) => {
    await visit(page, "/preview/prompt-input/default", "textarea");

    await page.getByRole("button", { name: "Submit" }).evaluate((button) => {
      button.disabled = true;
    });
    await page.locator("form").evaluate((form) => {
      window.promptSubmits = 0;
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        window.promptSubmits += 1;
      });
    });

    const textarea = page.locator("textarea");
    await textarea.fill("Keep editing");
    await textarea.press("Enter");

    expect(await page.evaluate(() => window.promptSubmits)).toBe(0);
    await expect(textarea).toHaveValue("Keep editing\n");
  });
});

const textFile = (name, text = "hello") => ({ name, mimeType: "text/plain", buffer: Buffer.from(text) });
const upload = (page) => page.locator("#files-form input[type=file]");
const attachments = (page) => page.getByRole("list", { name: "Attachments" }).getByRole("listitem");

async function contract(page) {
  await visit(page, "/preview/prompt-input/contract", "#files-prompt");
}

test("prompt input initializes its provider value and submits actual file data to its caller", async ({ page }) => {
  await contract(page);
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("Review these files");
  await upload(page).setInputFiles(textFile("notes.txt"));
  await expect(attachments(page)).toHaveCount(1);
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  await expect(page.getByRole("status")).toContainText("Submitted: Review these files");
  await expect(page.locator("#submitted-files")).toContainText('"filename":"notes.txt"');
  await expect(page.locator("#submitted-files")).toContainText('"url":"data:text/plain;base64,aGVsbG8="');
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("");
  await expect(attachments(page)).toHaveCount(0);
});

test("prompt input rejects wrong types and oversized files, then caps the accepted queue", async ({ page }) => {
  await contract(page);
  await upload(page).setInputFiles({ name: "image.png", mimeType: "image/png", buffer: Buffer.from("png") });
  await expect(page.getByRole("alert")).toHaveText("No files match the accepted types.");
  await expect(attachments(page)).toHaveCount(0);
  await upload(page).setInputFiles(textFile("large.txt", "x".repeat(17)));
  await expect(page.getByRole("alert")).toHaveText("All files exceed the maximum size.");
  await expect(attachments(page)).toHaveCount(0);
  await upload(page).setInputFiles([textFile("one.txt", "x".repeat(16)), textFile("two.txt"), textFile("three.txt")]);
  await expect(page.getByRole("alert")).toHaveText("Too many files. Some were not added.");
  await expect(attachments(page)).toHaveCount(2);
  await expect(attachments(page).first()).toContainText("one.txt");
  await expect(attachments(page).last()).toContainText("two.txt");
  await page.getByRole("button", { name: "Remove one.txt", exact: true }).click();
  await expect(attachments(page)).toHaveCount(1);
  await upload(page).setInputFiles(textFile("three.txt"));
  await expect(attachments(page)).toHaveCount(2);
  await expect(attachments(page).last()).toContainText("three.txt");
});

test("prompt input keeps a rejected draft and accepts a global file drop", async ({ page }) => {
  await contract(page);
  await page.evaluate(() => {
    const transfer = new DataTransfer();
    transfer.items.add(new File(["dropped"], "drop.txt", { type: "text/plain" }));
    document.body.dispatchEvent(new DragEvent("drop", { dataTransfer: transfer, bubbles: true, cancelable: true }));
  });
  await expect(attachments(page)).toHaveCount(1);
  await page.getByRole("textbox", { name: "Message" }).fill("retry");
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  await expect(page.getByRole("alert")).toHaveText("Please retry the submission.");
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("retry");
  await expect(attachments(page)).toHaveCount(1);
  await page.getByRole("textbox", { name: "Message" }).fill("");
  await page.getByRole("textbox", { name: "Message" }).press("Backspace");
  await expect(attachments(page)).toHaveCount(0);
});

test("prompt input accepts local drops without claiming file drops elsewhere", async ({ page }) => {
  await visit(page, "/preview/prompt-input/default", "textarea");
  const result = await page.evaluate(() => {
    const form = document.querySelector("form");
    const received = [];
    form.addEventListener("live-ai:prompt-files-change", (event) => received.push(event.detail.files.map((file) => file.filename)));
    const transfer = new DataTransfer();
    transfer.items.add(new File(["local"], "local.txt", { type: "text/plain" }));
    const outside = new DragEvent("drop", { dataTransfer: transfer, bubbles: true, cancelable: true });
    document.body.dispatchEvent(outside);
    const outsideCount = received.length;
    form.dispatchEvent(new DragEvent("drop", { dataTransfer: transfer, bubbles: true, cancelable: true }));
    return { outsideCount, received };
  });
  expect(result).toEqual({ outsideCount: 0, received: [["local.txt"]] });
});


test("a streaming prompt action calls Stop without submitting a new message", async ({ page }) => {
  await contract(page);
  const stop = page.getByRole("button", { name: "Stop", exact: true });
  await expect(stop).toHaveAttribute("type", "button");
  await stop.click();
  await expect(page.getByRole("status")).toHaveText("Generation stopped");
  await expect(page.getByRole("textbox", { name: "Message" })).toHaveValue("Review these files");
});

test("prompt tooltips show their text and keyboard shortcuts", async ({ page }) => {
  await visit(page, "/preview/prompt-input/tooltip", "#variant-message");
  for (const [id, text] of [["attach", "Attach files"], ["search", "Search the web ⌘K"], ["voice", "Voice input ⌘M"]]) {
    await page.locator(`#prompt-${id}-tooltip-trigger`).hover();
    await expect(page.locator(`#prompt-${id}-tooltip-popup`)).toHaveText(text);
    await expect(page.locator(`#prompt-${id}-tooltip-popup`)).toBeVisible();
    await page.mouse.move(0, 0);
  }
});

test("the cursor prompt adds reference files and selects a model", async ({ page }) => {
  await page.route("https://models.dev/logos/*.svg", (route) => route.fulfill({
    contentType: "image/svg+xml",
    body: '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"/>',
  }));
  await visit(page, "/preview/prompt-input/cursor", "#variant-message");
  await page.locator("#cursor-files-trigger").hover();
  const source = page.locator("#cursor-files-list [role=option]").filter({ hasText: "prompt-input.tsx" });
  await expect(source).toBeVisible();
  await source.click();
  await expect(page.locator("#variant-attachments")).toContainText("prompt-input.tsx");
  await page.keyboard.press("Escape");
  await page.locator("#variant-model-trigger").click();
  await page.getByRole("combobox", { name: "Search models" }).fill("Claude 4 Sonnet");
  await page.getByRole("combobox", { name: "Search models" }).press("Enter");
  await expect(page.locator("#variant-model-trigger")).toContainText("Claude 4 Sonnet");
});
