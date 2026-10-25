// Pixel capture starts two local applications and discovers both render state
// lists before it can photograph a state. Keep that startup allowance explicit.
const STARTUP_ALLOWANCE_MS = 20_000;
// A state taller than the minimum viewport makes four serial navigations, six
// for a busy capture, and two captures in one constrained renderer. This
// allowance keeps that bounded work inside the test deadline.
const PER_STATE_ALLOWANCE_MS = 20_000;
const MIN_TIMEOUT_MS = 120_000;

export function pixelTimeoutMs(stateCount) {
  if (!Number.isSafeInteger(stateCount) || stateCount < 1) {
    throw new RangeError(`visual state count must be a positive integer, got ${stateCount}`);
  }

  return Math.max(MIN_TIMEOUT_MS, STARTUP_ALLOWANCE_MS + stateCount * PER_STATE_ALLOWANCE_MS);
}
