// Each render state needs one React page and one LiveView page. Keep enough
// time for both, while keeping a broken action from holding a worker forever.
const SETUP_MS = 20_000;
const PER_STATE_MS = 12_000;
const MAX_MS = 300_000;

export function parityTimeoutMs(stateCount) {
  if (!Number.isSafeInteger(stateCount) || stateCount < 1) {
    throw new RangeError(`visual state count must be a positive integer, got ${stateCount}`);
  }

  return Math.min(MAX_MS, SETUP_MS + stateCount * PER_STATE_MS);
}
