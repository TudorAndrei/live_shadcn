export function rejectEvidenceStateFilter(environment = process.env) {
  if (environment.PARITY_DEBUG_STATE && environment.LIVE_SHADCN_BROWSER_VERIFY_WRAPPER) {
    throw new Error(
      "PARITY_DEBUG_STATE cannot be used in verification evidence runs; rerun without a state filter",
    );
  }
}
