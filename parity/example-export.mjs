import { parseSync } from "oxc-parser";

export function exampleExport(source, path) {
  const { program, errors } = parseSync(path, source);
  if (errors.length) throw new Error(`${path}: ${errors.map(error => error.message).join("; ")}`);
  for (const statement of program.body) {
    if (statement.type === "ExportDefaultDeclaration" && statement.declaration.type === "FunctionDeclaration") return "default";
  }
  for (const statement of program.body) {
    if (statement.type === "ExportNamedDeclaration" && statement.declaration?.type === "FunctionDeclaration") return statement.declaration.id.name;
  }
  throw new Error(`${path} has no exported example function`);
}
