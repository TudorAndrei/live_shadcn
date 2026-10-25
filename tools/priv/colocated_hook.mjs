// Bundles hook entries into the ES modules that colocated hook blocks hold.
//
// The request is JSON with a `hooks` list of `{ entry, export }`, where `entry`
// is an absolute path. Each result is the entry with every relative import
// inlined and tree-shaken, bare imports left as `import` statements, and the
// named export as the only, default export. Results keep the request order.
//
// The reply is written to its own file, so a warning that Node or a dependency
// prints to stdout or stderr cannot corrupt it.

import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { parseSync } from "oxc-parser";
import { walk } from "oxc-walker";
import { rolldown } from "rolldown";

const [requestPath, replyPath] = process.argv.slice(2);

if (!requestPath || !replyPath) {
  process.stderr.write("usage: node priv/colocated_hook.mjs <request.json> <reply.json>\n");
  process.exit(2);
}

const request = JSON.parse(readFileSync(requestPath, "utf8"));
const hooks = [];

for (const hook of request.hooks ?? []) {
  hooks.push(await bundle(hook));
}

writeFileSync(replyPath, JSON.stringify({ hooks }));

function local(id) {
  return id === "." || id === ".." || id.startsWith("./") || id.startsWith("../") || path.isAbsolute(id);
}

async function bundle({ entry, export: name }) {
  if (!exportsName(entry, name)) {
    return { error: `${entry} has no export named ${name}` };
  }

  const virtual = "\0colocated-hook-entry";

  try {
    const build = await rolldown({
      input: virtual,
      logLevel: "silent",
      experimental: { attachDebugInfo: "none" },
      // A bare specifier belongs to the application's bundler, which resolves
      // it from the application's own node_modules.
      external: (id, importer) => importer !== undefined && !local(id),
      plugins: [
        {
          name: "colocated-hook-entry",
          resolveId: (id) => (id === virtual ? id : null),
          load: (id) => (id === virtual ? `export { ${name} as default } from ${JSON.stringify(entry)};\n` : null),
        },
      ],
    });

    try {
      const { output } = await build.generate({ format: "esm", comments: false });
      const chunks = output.filter((item) => item.type === "chunk");

      if (chunks.length !== 1) {
        return { error: `${entry} bundled into ${chunks.length} chunks; a colocated hook is one module` };
      }

      return finish(chunks[0].code, name);
    } finally {
      await build.close();
    }
  } catch (error) {
    return { error: stripAnsi(String(error?.message ?? error)) };
  }
}

function exportsName(entry, name) {
  const { module } = parseSync(entry, readFileSync(entry, "utf8"));
  return module.staticExports.some((item) => item.entries.some((entry) => entry.exportName.name === name));
}

// The block is indented to its marker, so a string or template literal that
// spans lines would change value. A HEEx script body ends at `</script>` and
// runs through EEx first, and the `~H` heredoc ends at a delimiter line.
function finish(code, name) {
  const tail = `\nexport { ${name} as default };\n`;

  if (!code.endsWith(tail) || code.slice(0, -tail.length).includes("\nexport ")) {
    return { error: `the bundle of ${name} does not end with a single default export` };
  }

  const source = `${code.slice(0, -tail.length)}\nexport default ${name};\n`;
  const problem = unsafe(source);

  if (problem) {
    return { error: `the bundle of ${name} ${problem}` };
  }

  return { code: source.replace(/^\t+/gm, (tabs) => "  ".repeat(tabs.length)) };
}

function unsafe(source) {
  if (/<\/script/i.test(source)) return "contains `</script`, which ends a HEEx script body";
  if (source.includes("<%")) return "contains `<%`, which EEx reads inside a HEEx template";
  if (/^\s*('''|""")/m.test(source)) return "has a line that starts with a heredoc delimiter";

  const { program, errors } = parseSync("hook.js", source);

  if (errors.length > 0) return `does not parse: ${errors[0].message}`;

  let line = null;

  walk(program, {
    enter(node) {
      const raw = node.type === "TemplateElement" ? node.value.raw : node.type === "Literal" ? node.raw : null;

      if (line === null && raw?.includes("\n")) {
        line = source.slice(0, node.start).split("\n").length;
      }
    },
  });

  return line === null ? null : `has a literal that spans lines (bundle line ${line})`;
}

function stripAnsi(text) {
  return text.replace(/\u001b\[[0-9;]*m/g, "");
}
