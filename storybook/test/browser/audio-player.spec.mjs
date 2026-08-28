import { expect, test } from "@playwright/test";

import { visit } from "./live.mjs";

const controls = [
  "audio-player-play-button",
  "audio-player-seek-backward-button",
  "audio-player-seek-forward-button",
  "audio-player-time-display",
  "audio-player-time-range",
  "audio-player-duration-display",
  "audio-player-mute-button",
  "audio-player-volume-range",
];

test("the audio player has the complete official control bar", async ({ page }) => {
  await visit(page, "/preview/audio-player/default", "[data-slot='audio-player']");

  for (const slot of controls) {
    await expect(page.locator(`[data-slot='${slot}']`)).toBeVisible();
  }
});
