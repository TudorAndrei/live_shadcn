import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the microphone starts and stops speech recognition", async ({ page }) => {
  await page.addInitScript(() => {
    class SpeechRecognition {
      constructor() {
        window.testRecognition = this;
      }

      start() {
        this.onstart?.();
      }

      stop() {
        this.onend?.();
      }
    }

    window.SpeechRecognition = SpeechRecognition;
    window.webkitSpeechRecognition = SpeechRecognition;
  });

  await visit(page, "/preview/speech-input/default", "button[aria-label='Start dictation']");

  const input = page.locator("button[aria-label='Start dictation']").locator("..");
  const button = page.getByRole("button", { name: "Start dictation" });

  await button.click();
  await expect(input).toHaveAttribute("data-listening", "true");

  await page.evaluate(() => {
    const interim = Object.assign([{ transcript: "Draft words" }], { isFinal: false });
    const final = Object.assign([{ transcript: "Ship the component" }], { isFinal: true });
    window.testRecognition.onresult({ resultIndex: 0, results: [interim, final] });
  });
  await expect(page.locator("[data-speech-transcript]")).toHaveText("Ship the component");
  await expect(page.locator("[data-speech-transcript-card]")).toBeVisible();

  await button.click();
  await expect(input).toHaveAttribute("data-listening", "false");
  await page.locator("[data-speech-clear]").click();
  await expect(page.locator("[data-speech-empty]")).toBeVisible();
  await expect(page.locator("[data-speech-transcript-card]")).toBeHidden();
});
