export const pixelChromiumArgs = [
  "--force-color-profile=srgb",
  "--disable-lcd-text",
  "--disable-font-subpixel-positioning",
  "--disable-gpu",
  // Pixel checks keep one page per source. Limit renderer processes so that
  // old renderers do not retain memory between examples.
  "--renderer-process-limit=1",
  // Software raster work is CPU-heavy. One raster thread keeps the host usable
  // while it keeps the same pixel output and test coverage.
  "--num-raster-threads=1",
];
