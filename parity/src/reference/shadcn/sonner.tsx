"use client";

import { toast } from "sonner";

import { Button } from "@upstream/shadcn/ui/button";

// The pinned default export keeps these two public fixtures private. This
// adapter makes their unchanged action contracts addressable by the parity
// runner.
export function SonnerBasic() {
  return (
    <Button
      onClick={() => toast("Event has been created")}
      variant="outline"
      className="w-fit"
    >
      Show Toast
    </Button>
  );
}

export function SonnerWithDescription() {
  return (
    <Button
      onClick={() =>
        toast("Event has been created", {
          description: "Monday, January 3rd at 6:00pm",
        })
      }
      variant="outline"
      className="w-fit"
    >
      Show Toast
    </Button>
  );
}
