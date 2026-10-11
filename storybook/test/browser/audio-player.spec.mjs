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

test("the audio player plays, seeks, mutes, and changes volume", async ({ page }) => {
  // A real PCM file keeps playback checks independent of the sample host.
  const samples = 8000 * 30;
  const audio = Buffer.alloc(44 + samples * 2);
  audio.write("RIFF", 0);
  audio.writeUInt32LE(audio.length - 8, 4);
  audio.write("WAVEfmt ", 8);
  audio.writeUInt32LE(16, 16);
  audio.writeUInt16LE(1, 20);
  audio.writeUInt16LE(1, 22);
  audio.writeUInt32LE(8000, 24);
  audio.writeUInt32LE(16000, 28);
  audio.writeUInt16LE(2, 32);
  audio.writeUInt16LE(16, 34);
  audio.write("data", 36);
  audio.writeUInt32LE(samples * 2, 40);
  await page.route("**/ElevenLabs_*.mp3", (route) => {
    const range = route.request().headers().range?.match(/^bytes=(\d+)-(\d*)$/);
    const start = range ? Number(range[1]) : 0;
    const end = range?.[2] ? Number(range[2]) : audio.length - 1;
    return route.fulfill({
      status: range ? 206 : 200,
      contentType: "audio/wav",
      headers: {
        "accept-ranges": "bytes",
        ...(range ? { "content-range": `bytes ${start}-${end}/${audio.length}` } : {}),
      },
      body: audio.subarray(start, end + 1),
    });
  });
  await visit(page, "/preview/audio-player/default", "[data-slot='audio-player']");

  for (const slot of controls) {
    await expect(page.locator(`[data-slot='${slot}']`)).toBeVisible();
  }

  const media = page.locator("audio");
  const control = (slot) => page.locator(`[data-slot='audio-player-${slot}']`);
  await expect.poll(() => media.evaluate((element) => element.duration)).toBe(30);
  await control("play-button").click();
  await expect.poll(() => media.evaluate((element) => element.paused)).toBe(false);
  await control("play-button").click();
  await expect.poll(() => media.evaluate((element) => element.paused)).toBe(true);

  await control("seek-forward-button").click();
  await expect.poll(() => media.evaluate((element) => element.currentTime)).toBeGreaterThanOrEqual(10);
  await control("seek-backward-button").click();
  await expect.poll(() => media.evaluate((element) => element.currentTime)).toBeLessThan(2);
  await control("mute-button").click();
  await expect.poll(() => media.evaluate((element) => element.muted)).toBe(true);
  await control("mute-button").click();
  await expect.poll(() => media.evaluate((element) => element.muted)).toBe(false);
  const volume = control("volume-range").locator("input");
  await volume.focus();
  await volume.press("ArrowLeft");
  await expect.poll(() => media.evaluate((element) => element.volume)).toBeLessThan(1);
});
