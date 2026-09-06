export const pixelChromiumArgs = [
  "--force-color-profile=srgb",
  "--disable-lcd-text",
  "--disable-font-subpixel-positioning",
  "--disable-gpu",
  // Pixel checks use one page and visit the two sources in sequence. One
  // renderer process is sufficient and prevents old renderers from using
  // memory until Chrome removes them.
  "--renderer-process-limit=1",
  // Software raster work is CPU-heavy. One raster thread keeps the host usable
  // while it keeps the same pixel output and test coverage.
  "--num-raster-threads=1",
];
