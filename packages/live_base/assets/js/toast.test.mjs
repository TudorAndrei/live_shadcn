import assert from "node:assert/strict";
import test from "node:test";

import { Toast } from "./toast.js";

test("Toast reads Sonner's native toast marker without changing its output", () => {
  const toast = { id: "notice" };
  const hook = {
    el: {
      querySelectorAll(selector) {
        assert.equal(selector, "[data-slot='toast'], [data-sonner-toast]");
        return [toast];
      },
    },
  };

  assert.deepEqual(Toast.toasts.call(hook), [toast]);
});
