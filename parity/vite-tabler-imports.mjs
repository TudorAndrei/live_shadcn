import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, posix, resolve } from "node:path";

import { parseSync } from "oxc-parser";

const packageName = "@tabler/icons-react";

export function tablerImports() {
  const require = createRequire(import.meta.url);
  const packagePath = require.resolve(`${packageName}/package.json`);
  const { module } = JSON.parse(readFileSync(packagePath, "utf8"));
  const barrelPath = resolve(dirname(packagePath), module);
  const barrel = parseSync(barrelPath, readFileSync(barrelPath, "utf8"));
  if (barrel.errors.length) throw new Error(`Cannot parse ${barrelPath}: ${barrel.errors[0].message}`);

  // The pinned barrel defines aliases too, including names that do not match
  // their icon filename. Use its exports rather than derive paths from names.
  const icons = new Map();
  for (const statement of barrel.program.body) {
    if (statement.type !== "ExportNamedDeclaration" || !statement.source?.value.startsWith("./icons/")) continue;
    for (const specifier of statement.specifiers) {
      if (specifier.local.name === "default") {
        icons.set(specifier.exported.name, `${packageName}/${posix.join(posix.dirname(module), statement.source.value)}`);
      }
    }
  }

  return {
    name: "reference-tabler-imports",
    enforce: "pre",
    transform(source, id) {
      const filename = id.split("?")[0];
      if (filename.includes("/node_modules/") || !/\.[cm]?[jt]sx?$/.test(filename) || !source.includes(packageName)) return;
      const { program, errors } = parseSync(filename, source);
      if (errors.length) this.error(errors[0].message);
      let code = source;
      for (const statement of program.body.toReversed()) {
        if (statement.type !== "ImportDeclaration" || statement.source.value !== packageName || statement.importKind === "type" || statement.attributes.length) continue;
        const direct = [];
        const remaining = [];
        for (const specifier of statement.specifiers) {
          const path = specifier.type === "ImportSpecifier" && specifier.importKind !== "type"
            ? icons.get(specifier.imported.name ?? specifier.imported.value)
            : undefined;
          if (path) direct.push(`import ${specifier.local.name} from ${JSON.stringify(path)};`);
          else remaining.push(specifier);
        }
        if (!direct.length) continue;
        const named = remaining.filter(specifier => specifier.type === "ImportSpecifier");
        const clause = remaining.filter(specifier => specifier.type !== "ImportSpecifier")
          .map(specifier => source.slice(specifier.start, specifier.end));
        if (named.length) clause.push(`{ ${named.map(specifier => source.slice(specifier.start, specifier.end)).join(", ")} }`);
        if (clause.length) direct.push(`import ${clause.join(", ")} from ${source.slice(statement.source.start, statement.end)}`);
        code = code.slice(0, statement.start) + direct.join(" ") + code.slice(statement.end);
      }
      if (code !== source) return { code, map: null };
    },
  };
}
