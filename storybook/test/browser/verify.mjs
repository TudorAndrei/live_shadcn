import { spawn } from "node:child_process";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

import { acquireSourceLease, releaseSourceLease } from "../../../parity/source-lease.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../../..");
const defaultLeasePath = join(root, "parity", ".source-lease");
const localPlaywrightCli = join(here, "node_modules", "@playwright", "test", "cli.js");

function executeLocalPlaywright({ arguments: arguments_, environment, cwd = here }) {
  return new Promise((resolve_, reject) => {
    const child = spawn(process.execPath, [localPlaywrightCli, "test", ...arguments_], {
      cwd,
      env: environment,
      stdio: "inherit",
    });

    child.once("error", reject);
    child.once("exit", (code, signal) => resolve_({ code, signal }));
  });
}

export function embedVerificationReport(
  reportPath =
    process.env.PLAYWRIGHT_JSON_OUTPUT_FILE ??
    join(dirname(fileURLToPath(import.meta.url)), "results.json"),
) {
  const envelope = process.env.LIVE_SHADCN_VERIFY_ENVELOPE;

  if (!envelope || !existsSync(reportPath)) {
    return;
  }

  const report = JSON.parse(readFileSync(reportPath, "utf8"));
  report._live_shadcn_verification = JSON.parse(envelope);
  writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
}

export async function runVerification({
  arguments: arguments_ = process.argv.slice(2),
  environment = process.env,
  leasePath = defaultLeasePath,
  acquire = acquireSourceLease,
  release = releaseSourceLease,
  execute = executeLocalPlaywright,
} = {}) {
  const lease = await acquire(leasePath);

  try {
    const outcome = await execute({
      arguments: arguments_,
      environment: {
        ...environment,
        PARITY_SOURCE_LEASE_TOKEN: lease.token,
        LIVE_SHADCN_BROWSER_VERIFY_WRAPPER: "1",
      },
    });

    embedVerificationReport();
    return outcome;
  } finally {
    await release(leasePath, lease);
  }
}

function forwardOutcome({ code, signal }) {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exitCode = code ?? 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    forwardOutcome(await runVerification());
  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  }
}
