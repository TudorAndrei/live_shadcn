import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const player = (page) => page.locator("#transcription-audio");
const segments = (page) => page.locator("[data-slot='transcription-segment']");

test.describe("a transcription", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/transcription/default", "[data-slot='transcription']");
  });

  test("includes the source audio and its complete timed text", async ({ page }) => {
    await expect(player(page)).toHaveAttribute("controls", "");
    await expect(player(page).locator("source")).toHaveAttribute(
      "src",
      /ElevenLabs_2025-11-10T22_10_24_Hayden.*\.mp3$/,
    );
    await expect(segments(page)).toHaveCount(24);
    await expect(segments(page).first()).toHaveText("You");
    await expect(segments(page).last()).toHaveText("agents.");
  });

  test("marks timed words from the audio playhead", async ({ page }) => {
    await player(page).evaluate((audio) => {
      Object.defineProperty(audio, "currentTime", {
        configurable: true,
        value: 6.6,
        writable: true,
      });
      audio.dispatchEvent(new Event("timeupdate"));
    });

    await expect(segments(page).nth(18)).toHaveAttribute("data-active", "true");
    await expect(segments(page).nth(17)).toHaveClass(/text-muted-foreground/);
    await expect(segments(page).nth(19)).toHaveClass(/text-muted-foreground\/60/);
  });

  test("selecting a word seeks without a server event", async ({ page }) => {
    const events = [];
    page.on("websocket", (socket) =>
      socket.on("framesent", ({ payload }) => events.push(String(payload))),
    );

    await player(page).evaluate((audio) => {
      Object.defineProperty(audio, "currentTime", {
        configurable: true,
        value: 0,
        writable: true,
      });
    });

    await segments(page).nth(10).click();

    await expect.poll(() => player(page).evaluate((audio) => audio.currentTime)).toBe(3.48);
    await expect(segments(page).nth(10)).toHaveAttribute("data-active", "true");
    expect(events.filter((frame) => frame.includes("event"))).toEqual([]);
  });
});
