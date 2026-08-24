import { useEffect, useRef } from "react";

import { Toaster, createToastManager } from "@upstream/shadcn/ui/toast";

// Ported from `StorybookWeb.Examples.toast_default/1`.
//
// React holds its own toast manager, while the LiveView example keeps the same
// list on the server. Both render the same three messages and limit the visible
// stack to two, which is what the comparison can judge.
export default function ToastDefault() {
  const manager = useRef(createToastManager()).current;
  const seeded = useRef(false);

  useEffect(() => {
    if (seeded.current) return;
    seeded.current = true;

    manager.add({ type: "info", title: "Spec written", description: "53 components read." });
    manager.add({ type: "success", title: "Generated", description: "Nothing was typed by hand." });
    manager.add({ type: "warning", title: "Upstream moved", description: "Two digests changed." });
  }, [manager]);

  return <Toaster toastManager={manager} timeout={0} limit={2} />;
}
