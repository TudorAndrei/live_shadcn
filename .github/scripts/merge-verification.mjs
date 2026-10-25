import { readFileSync, readdirSync, renameSync, writeFileSync } from "node:fs";
import { resolve, join } from "node:path";
import { fileURLToPath } from "node:url";

export function mergeVerification(matrix, reports) {
  const expected = new Map(matrix.include.map((entry) => [entry.shard, entry.components]));
  const results = {};
  const seen = new Set();

  if (expected.size !== matrix.include.length || expected.size === 0) {
    throw new Error("verification plan must contain unique, nonempty shards");
  }

  for (const report of reports) {
    const components = expected.get(report.shard);
    if (!components?.length || seen.has(report.shard) ||
        !["shadcn", "ai_elements"].includes(report.source) ||
        components.some((key) => !key.startsWith(`${report.source}/`))) {
      throw new Error("unknown or duplicate verification shard");
    }
    const keys = Object.keys(report.results).sort();
    if (JSON.stringify(keys) !== JSON.stringify([...components].sort()) ||
        JSON.stringify([...report.components].sort()) !== JSON.stringify(keys)) {
      throw new Error("verification shard does not contain its complete assigned scope");
    }
    for (const key of keys) {
      if (Object.hasOwn(results, key) || report.results[key]?.pass !== true) {
        throw new Error(`duplicate or failed verification result: ${key}`);
      }
      results[key] = report.results[key];
    }
    seen.add(report.shard);
  }
  if (seen.size !== expected.size) throw new Error("missing verification shards");
  return results;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [directory, output] = process.argv.slice(2);
  if (!directory || !output || !process.env.VERIFICATION_MATRIX) {
    throw new Error("provide REPORT_DIRECTORY OUTPUT_JSON and VERIFICATION_MATRIX");
  }
  const reports = readdirSync(directory).filter((name) => name.endsWith(".json"))
    .map((name) => JSON.parse(readFileSync(join(directory, name), "utf8")));
  const results = mergeVerification(JSON.parse(process.env.VERIFICATION_MATRIX), reports);
  const existing = JSON.parse(readFileSync(output, "utf8"));
  const temporary = `${output}.${process.pid}.tmp`;
  writeFileSync(temporary, `${JSON.stringify({ ...existing, ...results }, null, 2)}\n`);
  renameSync(temporary, output);
  console.log(`Merged ${Object.keys(results).length} complete component records.`);
}
