export function serverPolicy(env = process.env) {
  const managed = env.LIVE_SHADCN_MANAGED_SERVERS === "1";
  const prepared = env.PARITY_PREPARED === "1";

  return {
    parityCommand: managed || prepared ? "npm run dev:prepared" : "npm run dev",
    reuseExistingServer: managed,
  };
}

export function assertVerificationInvocation(env = process.env) {
  if (
    env.LIVE_SHADCN_MANAGED_SERVERS === "1" ||
    env.LIVE_SHADCN_BROWSER_VERIFY_WRAPPER === "1"
  ) {
    return;
  }

  throw new Error(
    "direct Playwright verification is not allowed. Run `npm run verify` so it takes the shared source lease.",
  );
}
