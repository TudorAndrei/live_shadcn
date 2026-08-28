import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

test("the microphone starts and stops speech recognition", async ({ page }) => {
  await page.addInitScript(() => {
    class SpeechRecognition {
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
  await expect(button).toHaveAttribute("aria-pressed", "true");

  await button.click();
  await expect(input).toHaveAttribute("data-listening", "false");
  await expect(button).toHaveAttribute("aria-pressed", "false");
});
