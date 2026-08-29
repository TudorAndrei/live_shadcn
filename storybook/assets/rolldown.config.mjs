// The asset bundle, and the two things it must never do quietly.
//
// `live_base` is installed as a symlink to `../../packages/live_base`, so a
// bare import inside it resolves from that real path — where there is no
// `node_modules`. Named here, `@floating-ui/dom` resolves from the one
// `npm ci` fills, wherever the importer happens to live.
//
// An import nobody can resolve is left as an external, and an iife then expects
// a global that is not there: the bundle throws on load, the page has no
// LiveView, and every click is a full reload. Rolldown says so in a warning and
// exits zero, so `onwarn` turns that one into a failure.
//
// `--minify` on the command line is honoured beside `-c`, which is how the
// deploy script asks for it.

import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

export default {
  input: "js/app.js",
  platform: "browser",
  resolve: {
    alias: {
      "@floating-ui/dom": require.resolve("@floating-ui/dom"),
      "@rive-app/webgl2": require.resolve("@rive-app/webgl2"),
    },
  },
  output: {
    dir: "../priv/static/assets",
    format: "iife",
  },
  onwarn(warning, warn) {
    if (["UNRESOLVED_IMPORT", "MISSING_GLOBAL_NAME"].includes(warning.code)) {
      throw new Error(`${warning.code}: ${warning.message}`);
    }

    warn(warning);
  },
};
