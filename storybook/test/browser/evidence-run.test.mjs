import assert from "node:assert/strict";
import test from "node:test";

import { rejectEvidenceStateFilter } from "./evidence-run.mjs";

test("verification evidence runs reject PARITY_DEBUG_STATE filters", () => {
  assert.throws(
    () =>
      rejectEvidenceStateFilter({
        PARITY_DEBUG_STATE: "expanded:Open",
        LIVE_SHADCN_BROWSER_VERIFY_WRAPPER: "1",
      }),
    /PARITY_DEBUG_STATE cannot be used in verification evidence runs/,
  );
});

test("diagnostic state filters remain available outside verification evidence runs", () => {
  assert.doesNotThrow(() =>
    rejectEvidenceStateFilter({
      PARITY_DEBUG_STATE: "expanded:Open",
    }),
  );
});
