import { spawn } from "node:child_process";
import { readFileSync, writeFileSync, existsSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

import { acquireSourceLease, releaseSourceLease, useSourceLease } from "../../../parity/source-lease.mjs";
import { completedEnvelope } from "./report-provenance.mjs";
import { directEnvelope } from "./direct-report.mjs";
import { rejectEvidenceStateFilter } from "./evidence-run.mjs";

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
    join(here, "results.json"),
  envelope = process.env.LIVE_SHADCN_VERIFY_ENVELOPE,
  outcome = { code: 0, signal: null },
) {

  if (!envelope || !existsSync(reportPath)) {
    return;
  }

  const report = JSON.parse(readFileSync(reportPath, "utf8"));
  report._live_shadcn_verification = completedEnvelope(report, JSON.parse(envelope), outcome);
  writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
}

export async function runVerification({
  arguments: arguments_ = process.argv.slice(2),
  environment = process.env,
  leasePath = defaultLeasePath,
  acquire = acquireSourceLease,
  release = releaseSourceLease,
  execute = executeLocalPlaywright,
  prepareEnvelope = directEnvelope,
} = {}) {
  if (environment.PREVIEW_SOURCE && environment.PREVIEW_SOURCE !== "shadcn") {
    throw new Error("verification supports only source shadcn");
  }

  const run = async (token) => {
    rejectEvidenceStateFilter({ ...environment, LIVE_SHADCN_BROWSER_VERIFY_WRAPPER: "1" });
    const envelope = environment.LIVE_SHADCN_VERIFY_ENVELOPE ||
      JSON.stringify(prepareEnvelope(arguments_, environment));
    const reportPath = resolve(here, environment.PLAYWRIGHT_JSON_OUTPUT_FILE || "results.json");
    // A failed child must never leave an earlier report available for import.
    rmSync(reportPath, { force: true });
    const outcome = await execute({
      arguments: arguments_,
      environment: {
        ...environment,
        PREVIEW_SOURCE: "shadcn",
        PLAYWRIGHT_JSON_OUTPUT_FILE: reportPath,
        PARITY_SOURCE_LEASE_TOKEN: token,
        LIVE_SHADCN_BROWSER_VERIFY_WRAPPER: "1",
        LIVE_SHADCN_VERIFY_ENVELOPE: envelope,
      },
    });

    embedVerificationReport(reportPath, envelope, outcome);
    return outcome;
  };

  const parentToken = environment.PARITY_SOURCE_LEASE_TOKEN;
  if (parentToken) {
    return useSourceLease(leasePath, parentToken, () => run(parentToken));
  }

  const lease = await acquire(leasePath);
  try {
    return await run(lease.token);
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
