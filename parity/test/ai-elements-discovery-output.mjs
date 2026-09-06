import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { discovery } from "../src/official-ai-elements.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
const manifest = JSON.parse(readFileSync(join(root, "registry/UPSTREAM.json"), "utf8"));

console.log(JSON.stringify(discovery(manifest)));
